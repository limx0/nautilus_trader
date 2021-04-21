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

import pytest

from model.objects import Price
from nautilus_trader.model.c_enums.order_side import OrderSide
from nautilus_trader.model.objects import Quantity
from nautilus_trader.model.orderbook.level import Level
from nautilus_trader.model.orderbook.order import Order


@pytest.fixture
def empty_level():
    return Level()


def test_init(empty_level):
    assert len(empty_level.orders) == 0


def test_add(empty_level):
    order = Order(price=Price(10), volume=Quantity(100), side=OrderSide.BUY, id="1")
    empty_level.add(order=order)
    assert len(empty_level.orders) == 1


def test_update():
    order = Order(price=Price(10), volume=Quantity(100), side=OrderSide.BUY)
    level = Level(orders=[order])
    assert level.volume() == 100
    order.update_volume(volume=Quantity(50))
    level.update(order=order)
    assert level.volume() == 50


def test_delete_order():
    orders = [
        Order(price=Price(100), volume=Quantity(50), side=OrderSide.BUY, id="1"),
        Order(price=Price(100), volume=Quantity(50), side=OrderSide.BUY, id="2"),
    ]
    level = Level(orders=orders)
    level.delete(order=orders[1])
    assert level.volume() == 50


def test_zero_volume_level():
    level = Level(
        orders=[Order(price=Price(10), volume=Quantity(0), side=OrderSide.BUY)]
    )
    assert level.volume() == 0
