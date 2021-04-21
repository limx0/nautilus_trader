# -------------------------------------------------------------------------------------------------
#  Copyright (C) 2015-2021 Nautech Systems Pty Ltd. All rights reserved.
#  https://nautechsystems.io
#
#  Licensed under the GNU Lesser General Public License Version 3.0 (the "License");
#  You may not use this file except in compliance with the License.
#  You may obtain a copy of the License at https://www.gnu.org/licenses/lgpl-3.0.en.html
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# -------------------------------------------------------------------------------------------------
from decimal import Decimal
import logging

from nautilus_trader.core.correctness cimport Condition
from nautilus_trader.core.functions cimport bisect_double_right
from nautilus_trader.model.objects cimport BaseDecimal
from nautilus_trader.model.objects cimport Price
from nautilus_trader.model.objects cimport Quantity
from nautilus_trader.model.orderbook.level cimport Level
from nautilus_trader.model.orderbook.order cimport Order


logger = logging.getLogger(__name__)


cdef class Ladder:
    """
    Represents a ladder of orders in a book.
    """
    def __init__(self, bint is_bid):
        """
        Initialize a new instance of the `Ladder` class.

        Parameters
        ----------
        is_bid : bool
            If the ladder should be represented in reverse order of price.

        """
        self.is_bid = is_bid
        self.levels = []           # type: list[Level]
        self.order_id_levels = {}  # type: dict[str, Level]

    cpdef bint reverse(self) except *:
        return self.is_bid

    def __repr__(self):
        return f"Ladder({self.levels})"

    cpdef void add(self, Order order) except *:
        """
        Add the given order to the ladder.

        Parameters
        ----------
        order : Order
            The order to add.

        """
        Condition.not_none(order, "order")

        # Level exists, add new order
        cdef int price_idx
        cdef Level level
        existing_prices = self.prices()
        if order.price in existing_prices:
            price_idx = existing_prices.index(order.price)
            level = self.levels[price_idx]
            level.add(order=order)
        # New price, create Level
        else:
            level = Level(orders=[order])
            price_idx = bisect_double_right(existing_prices, level.price())
            self.levels.insert(price_idx, level)
        self.order_id_levels[order.id] = level

    cpdef void update(self, Order order) except *:
        """
        Update the given order in the ladder.

        Parameters
        ----------
        order : Order
            The order to add.

        """
        Condition.not_none(order, "order")

        if order.id not in self.order_id_levels:
            self.add(order=order)
            return

        # Find the existing order
        cdef Level level = self.order_id_levels[order.id]
        if order.price == level.price():
            # This update contains a volume update
            level.update(order=order)
        else:
            # New price for this order, delete and insert
            self.delete(order=order)
            self.add(order=order)

    cpdef void delete(self, Order order) except *:
        """
        Delete the given order in the ladder.

        Parameters
        ----------
        order : Order

        """
        Condition.not_none(order, "order")
        if order.id not in self.order_id_levels:
            # TODO - we could emit a better error here about book integrity?
            logger.warning(f"Couldn't find order_id {order.id} in levels, SKIPPING!")
            return
        cdef Level level = self.order_id_levels[order.id]
        cdef int price_idx = self.prices().index(level.price())
        level.delete(order=order)
        del self.order_id_levels[order.id]
        if not level.orders:
            del self.levels[price_idx]

    cpdef list depth(self, int n=1):
        """
        Return the levels in the ladder to the given depth.

        Parameters
        ----------
        n : int
            The maximum level to query.

        Returns
        -------
        list[Level]

        """
        if not self.levels:
            return []
        n = n or len(self.levels)
        return list(reversed(self.levels[-n:])) if self.reverse() else self.levels[:n]

    cpdef list prices(self):
        """
        The prices in the ladder.

        Returns
        -------
        list[double]

        """
        return [level.price() for level in self.levels]

    cpdef list volumes(self):
        """
        The volumes in the ladder.

        Returns
        -------
        list[double]

        """
        return [level.volume() for level in self.levels]

    cpdef list exposures(self):
        """
        The exposures in the ladder.

        Returns
        -------
        list[double]

        """
        return [level.exposure() for level in self.levels]

    cpdef Level top(self):
        """
        The top Level in the ladder.

        Returns
        -------
        Level or None

        """
        cdef list top = self.depth(1)
        if top:
            return top[0]
        else:
            return None

    cpdef Quantity depth_at_price(self, Price price, DepthType depth_type=DepthType.VOLUME):
        """
        Find the depth (volume or exposure) that would be filled at a given price
        """
        cdef int depth = 0
        cdef list levels = self.levels if not self.reverse() else self.levels[::-1]

        for level in levels:
            if not self.is_bid:
                if price >= level.price():
                    print("Adding to depth")
                    depth += level.volume() if depth_type == DepthType.VOLUME else level.exposure()
                else:
                    break
            else:
                if price <= level.price():
                    depth += level.volume() if depth_type == DepthType.VOLUME else level.exposure()
                else:
                    break
        return Quantity(depth)

    cpdef volume_fill_price(self, Quantity volume, bint partial_ok=True):
        """
        Returns the average price that a certain volume order would be filled at

        :param volume: The volume to be filled
        :param partial_ok: return a value even if the total volume would not be matched
        :return:
        """
        return self._depth_for_value(value=volume, depth_type=DepthType.VOLUME, partial_ok=partial_ok)

    cpdef exposure_fill_price(self, Quantity exposure, bint partial_ok=True):
        """
        Returns the average price that a certain exposure order would be filled at
        """
        return self._depth_for_value(value=exposure, depth_type=DepthType.VOLUME, partial_ok=partial_ok)

    cpdef _depth_for_value(self, Quantity value, DepthType depth_type=DepthType.VOLUME, bint partial_ok=True):
        """
        Find the levels in this ladder required to fill a certain volume or exposure
        """
        cdef list levels = self.levels if not self.reverse() else self.levels[::-1]
        cdef Quantity cumulative_value = Quantity(0)
        cdef Quantity current = Quantity(0)
        cdef list value_volumes = []

        for level in levels:
            for order in level.orders:
                current = order.volume if depth_type == DepthType.VOLUME else order.exposure()
                if current >= value:
                    # We are totally filled, early exit
                    return order.price
                elif value >= (cumulative_value + current):
                    # Add this order and continue
                    value_volumes.append((current, order.price))
                    cumulative_value = Quantity(cumulative_value + current)
                elif (cumulative_value + current) >= value:
                    # This order has filled us, calc and return
                    value_volumes.append((value - cumulative_value, order.price))
                    break
                print(value, current, cumulative_value, value_volumes, order)
        print("Done", cumulative_value, value)
        if not partial_ok and cumulative_value < value:
            return
        return sum([(price * val / cumulative_value) for val, price in value_volumes])
