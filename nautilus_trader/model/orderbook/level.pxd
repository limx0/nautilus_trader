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

from nautilus_trader.model.orderbook.order cimport Order


# cdef union MaybeDouble:
#     double value
#     bint has_value


cdef class Level:
    cdef readonly list orders
    """The orders at the level.\n\n:returns: `list[Order]`"""

    cpdef void add(self, Order order) except *
    cpdef void update(self, Order order) except *
    cpdef void delete(self, Order order) except *

    cpdef double volume(self) except *
    cpdef price(self)
    cpdef list iter_orders(self)

    # cdef double volume_c(self) except *
    # cdef MaybeDouble price_c(self) except *

    cdef inline bint _check_price(self, Order order) except *
