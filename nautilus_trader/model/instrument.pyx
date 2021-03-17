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

from cpython.datetime cimport datetime

from decimal import Decimal

from nautilus_trader.core.correctness cimport Condition
from nautilus_trader.model.c_enums.asset_class cimport AssetClass
from nautilus_trader.model.c_enums.asset_type cimport AssetType
from nautilus_trader.model.c_enums.liquidity_side cimport LiquiditySide
from nautilus_trader.model.c_enums.liquidity_side cimport LiquiditySideParser
from nautilus_trader.model.c_enums.position_side cimport PositionSide
from nautilus_trader.model.currency cimport Currency
from nautilus_trader.model.identifiers cimport InstrumentId
from nautilus_trader.model.objects cimport Quantity


cdef class Instrument:
    """
    Represents a tradeable financial market instrument.
    """

    def __init__(
        self,
        InstrumentId instrument_id not None,
        AssetClass asset_class,
        AssetType asset_type,
        Currency base_currency,  # Can be None
        Currency quote_currency not None,
        Currency settlement_currency not None,
        bint is_inverse,
        int price_precision,
        int size_precision,
        tick_size not None: Decimal,
        multiplier not None: Decimal,
        Quantity lot_size not None,
        Quantity max_quantity,  # Can be None
        Quantity min_quantity,  # Can be None
        Money max_notional,     # Can be None
        Money min_notional,     # Can be None
        Price max_price,        # Can be None
        Price min_price,        # Can be None
        margin_init not None: Decimal,
        margin_maint not None: Decimal,
        maker_fee not None: Decimal,
        taker_fee not None: Decimal,
        dict financing not None,
        datetime timestamp not None,
        dict info=None,
    ):
        """
        Initialize a new instance of the `Instrument` class.

        Parameters
        ----------
        instrument_id : InstrumentId
            The instrument identifier for the instrument.
        asset_class : AssetClass
            The instrument asset class.
        asset_type : AssetType
            The instrument asset type.
        base_currency : Currency, optional
            The base currency. Not applicable for all asset classes.
        quote_currency : Currency
            The quote currency.
        settlement_currency : Currency
            The settlement currency.
        is_inverse : Currency
            If the instrument costing is inverse (quantity expressed in quote currency units).
        price_precision : int
            The price decimal precision.
        size_precision : int
            The trading size decimal precision.
        tick_size : Decimal
            The tick size.
        multiplier : Decimal
            The contract value multiplier.
        lot_size : Quantity
            The rounded lot unit size.
        max_quantity : Quantity
            The maximum possible order quantity.
        min_quantity : Quantity
            The minimum possible order quantity.
        max_notional : Money
            The maximum possible order notional value.
        min_notional : Money
            The minimum possible order notional value.
        max_price : Price
            The maximum possible printed price.
        min_price : Price
            The minimum possible printed price.
        margin_init : Decimal
            The initial margin requirement in percentage of order value.
        margin_maint : Decimal
            The maintenance margin in percentage of position value.
        maker_fee : Decimal
            The fee rate for liquidity makers as a percentage of order value.
        taker_fee : Decimal
            The fee rate for liquidity takers as a percentage of order value.
        financing : dict[str, object]
            The financing information for the instrument.
        timestamp : datetime
            The timestamp the instrument was created/updated at.
        info : dict[str, object], optional
            The additional instrument information.

        Raises
        ------
        ValueError
            If asset_class is UNDEFINED.
        ValueError
            If asset_type is UNDEFINED.
        ValueError
            If price_precision is negative (< 0).
        ValueError
            If size_precision is negative (< 0).
        ValueError
            If tick_size is not positive (> 0).
        ValueError
            If multiplier is not positive (> 0).
        ValueError
            If lot size is not positive (> 0).
        ValueError
            If max_quantity is not positive (> 0).
        ValueError
            If min_quantity is negative (< 0).
        ValueError
            If max_notional is not positive (> 0).
        ValueError
            If min_notional is negative (< 0).
        ValueError
            If max_price is not positive (> 0).
        ValueError
            If min_price is negative (< 0).

        """
        Condition.not_equal(asset_class, AssetClass.UNDEFINED, "asset_class", "UNDEFINED")
        Condition.not_equal(asset_type, AssetType.UNDEFINED, "asset_type", "UNDEFINED")
        Condition.not_negative_int(price_precision, 'price_precision')
        Condition.not_negative_int(size_precision, 'volume_precision')
        Condition.type(tick_size, Decimal, "tick_size")
        Condition.positive(tick_size, "tick_size")
        Condition.type(multiplier, Decimal, "multiplier")
        Condition.positive(multiplier, "multiplier")
        Condition.positive(lot_size, "lot_size")
        if max_quantity is not None:
            Condition.positive(max_quantity, "max_quantity")
        if min_quantity is not None:
            Condition.not_negative(min_quantity, "min_quantity")
        if max_notional is not None:
            Condition.positive(max_notional, "max_notional")
        if min_notional is not None:
            Condition.not_negative(min_notional, "min_notional")
        if max_price is not None:
            Condition.positive(max_price, "max_price")
        if min_price is not None:
            Condition.not_negative(min_price, "min_price")
        Condition.type(margin_init, Decimal, "margin_init")
        Condition.not_negative(margin_init, "margin_init")
        Condition.type(margin_maint, Decimal, "margin_maint")
        Condition.not_negative(margin_maint, "margin_maint")
        Condition.type(maker_fee, Decimal, "maker_fee")
        Condition.type(taker_fee, Decimal, "taker_fee")
        super().__init__(timestamp)

        self.id = instrument_id
        self.symbol = instrument_id.symbol
        self.venue = instrument_id.venue
        self.asset_class = asset_class
        self.asset_type = asset_type
        self.base_currency = base_currency  # Can be None
        self.quote_currency = quote_currency
        # Currently not handling quanto settlement
        self.settlement_currency = quote_currency if not is_inverse else base_currency
        self.is_inverse = is_inverse
        self.is_quanto = self._is_quanto(base_currency, quote_currency, settlement_currency)
        self.price_precision = price_precision
        self.size_precision = size_precision
        self.tick_size = tick_size
        self.multiplier = multiplier
        self.lot_size = lot_size
        self.max_quantity = max_quantity
        self.min_quantity = min_quantity
        self.max_notional = max_notional
        self.min_notional = min_notional
        self.max_price = max_price
        self.min_price = min_price
        self.margin_init = margin_init
        self.margin_maint = margin_maint
        self.maker_fee = maker_fee
        self.taker_fee = taker_fee

    cdef bint _is_quanto(
        self,
        Currency base_currency,
        Currency quote_currency,
        Currency settlement_currency,
    ) except *:
        if base_currency is None:
            return False

        return settlement_currency != base_currency and settlement_currency != quote_currency

    def __eq__(self, Instrument other) -> bool:
        return self.id.value == other.id.value

    def __ne__(self, Instrument other) -> bool:
        return self.id.value != other.id.value

    def __hash__(self) -> int:
        return hash(self.id.value)

    def __repr__(self) -> str:
        return f"{type(self).__name__}('{self.id.value}')"

    cpdef Money market_value(
        self,
        Quantity quantity,
        close_price: Decimal,
        leverage: Decimal=None,
    ):
        """
        Calculate the market value from the given parameters.

        Parameters
        ----------
        quantity : Quantity
            The total quantity.
        close_price : Decimal or Price
            The closing price.
        leverage : Decimal, optional
            The leverage for the position.

        Returns
        -------
        Money
            In the settlement currency.

        """
        if leverage is None:
            leverage = Decimal(1)
        Condition.not_none(quantity, "quantity")
        Condition.type(close_price, (Decimal, Price), "close_price")
        Condition.not_none(close_price, "close_price")
        Condition.not_none(leverage, "leverage")

        if self.is_inverse:
            close_price = 1 / close_price

        market_value: Decimal = (quantity * close_price * self.multiplier) / leverage
        return Money(market_value, self.settlement_currency)

    cpdef Money notional_value(self, Quantity quantity, close_price: Decimal):
        """
        Calculate the notional value from the given parameters.

        Parameters
        ----------
        quantity : Quantity
            The total quantity.
        close_price : Decimal or Price
            The closing price.

        Returns
        -------
        Money
            In the settlement currency.

        """
        Condition.not_none(quantity, "quantity")
        Condition.type(close_price, (Decimal, Price), "close_price")
        Condition.not_none(close_price, "close_price")

        if self.is_inverse:
            close_price = 1 / close_price

        notional_value: Decimal = quantity * close_price * self.multiplier
        return Money(notional_value, self.settlement_currency)

    cpdef Money calculate_initial_margin(
        self,
        Quantity quantity,
        Price price,
        leverage: Decimal=None,
    ):
        """
        Calculate the initial margin from the given parameters.

        Parameters
        ----------
        quantity : Quantity
            The order quantity.
        price : Price
            The order price.
        leverage : Decimal, optional
            The leverage for the position.

        Returns
        -------
        Money
            In the settlement currency.

        """
        if leverage is None:
            leverage = Decimal(1)
        Condition.not_none(quantity, "quantity")
        Condition.not_none(price, "price")
        Condition.not_none(leverage, "leverage")

        if leverage == 1:
            return Money(0, self.settlement_currency)  # No margin necessary

        notional = self.notional_value(quantity, price)
        margin = notional / leverage * self.margin_init
        margin += notional * self.taker_fee * 2

        return Money(margin, self.settlement_currency)

    cpdef Money calculate_maint_margin(
        self,
        PositionSide side,
        Quantity quantity,
        Price last,
        leverage: Decimal=None,
    ):
        """
        Calculate the maintenance margin from the given parameters.

        Parameters
        ----------
        side : PositionSide (Enum)
            The currency position side.
        quantity : Quantity
            The currency position quantity.
        last : Price
            The position instruments last price.
        leverage : Decimal, optional
            The leverage for the position.

        Returns
        -------
        Money
            In the settlement currency.

        """
        if leverage is None:
            leverage = Decimal(1)
        # side checked in _get_close_price
        Condition.not_none(quantity, "quantity")
        Condition.not_none(last, "last")
        Condition.not_none(leverage, "leverage")

        if leverage == 1:
            return Money(0, self.settlement_currency)  # No margin necessary

        notional = self.notional_value(quantity, last)
        margin = (notional / leverage) * self.margin_maint
        margin += notional * self.taker_fee

        return Money(margin, self.settlement_currency)

    cpdef Money calculate_commission(
        self,
        Quantity quantity,
        avg_price: Decimal,
        LiquiditySide liquidity_side,
    ):
        """
        Calculate the commission generated from a transaction with the given
        parameters.

        Parameters
        ----------
        quantity : Quantity
            The quantity for the transaction.
        avg_price : Decimal or Price
            The average transaction price.
        liquidity_side : LiquiditySide (Enum)
            The liquidity side for the transaction.

        Returns
        -------
        Money
            In the settlement currency.

        Raises
        ------
        ValueError
            If liquidity_side is NONE.

        """
        Condition.not_none(quantity, "quantity")
        Condition.type(avg_price, (Decimal, Price), "avg_price")
        Condition.not_equal(liquidity_side, LiquiditySide.NONE, "liquidity_side", "NONE")

        notional: Decimal = self.notional_value(quantity, avg_price)

        if liquidity_side == LiquiditySide.MAKER:
            commission: Decimal = notional * self.maker_fee
        elif liquidity_side == LiquiditySide.TAKER:
            commission: Decimal = notional * self.taker_fee
        else:
            raise RuntimeError(f"invalid LiquiditySide, "
                               f"was {LiquiditySideParser.to_str(liquidity_side)}")

        return Money(commission, self.settlement_currency)


# # TODO: Finish docs
cdef class Future(Instrument):
    """
    Represents a futures contract.
    """

    def __init__(
        self,
        InstrumentId instrument_id not None,
        AssetClass asset_class,
        Currency currency not None,
        str expiry not None,
        int contract_id,
        str local_symbol not None,
        str trading_class not None,
        str market_name not None,
        str long_name not None,
        str contract_month not None,
        str time_zone_id not None,
        str trading_hours not None,
        str liquid_hours not None,
        str last_trade_time not None,
        int multiplier,
        int price_precision,
        tick_size not None: Decimal,
        Quantity lot_size not None,
        datetime timestamp not None,
    ):
        """
        Initialize a new instance of the `Future` class.

        Parameters
        ----------
        instrument_id : InstrumentId
            The instrument identifier.
        asset_class : AssetClass
            The futures contract asset class.
        currency : Currency
            The futures contract currency.
        price_precision : int
            The price decimal precision.
        tick_size : Decimal
            The tick size.
        timestamp : datetime
            The timestamp the instrument was created/updated at.

        Raises
        ------
        ValueError
            If asset_class is UNDEFINED.
        ValueError
            If multiplier is not positive (> 0).
        ValueError
            If price_precision is negative (< 0).
        ValueError
            If tick_size is not positive (> 0).
        ValueError
            If lot size is not positive (> 0).

        """
        Condition.positive_int(multiplier, "multiplier")
        super().__init__(
            instrument_id=instrument_id,
            asset_class=asset_class,
            asset_type=AssetType.FUTURE,
            base_currency=None,  # N/A
            quote_currency=currency,
            settlement_currency=currency,
            is_inverse=False,
            price_precision=price_precision,
            size_precision=0,  # No fractional contracts
            tick_size=tick_size,
            multiplier=Decimal(multiplier),
            lot_size=lot_size,
            max_quantity=None,
            min_quantity=Quantity(1),
            max_notional=None,
            min_notional=None,
            max_price=None,
            min_price=None,
            margin_init=Decimal(),
            margin_maint=Decimal(),
            maker_fee=Decimal(),
            taker_fee=Decimal(),
            financing={},
            timestamp=timestamp,
            info={},
        )

        self.contract_id = contract_id
        self.last_trade_date_or_contract_month = expiry
        self.local_symbol = local_symbol
        self.trading_class = trading_class
        self.market_name = market_name
        self.long_name = long_name
        self.contract_month = contract_month
        self.time_zone_id = time_zone_id
        self.trading_hours = trading_hours
        self.liquid_hours = liquid_hours
        self.last_trade_time = last_trade_time


cdef class BettingInstrument:
    def __init__(
        self,
        instrument_id: str,
        competition_id: str,
        competition_name: str,
        event_country_code: str,
        event_description: str,
        event_id: str,
        event_name: str,
        event_open_date: str,
        event_timezone: str,
        event_type_id: str,
        event_type_name: str,
        market_id: str,
        market_name: str,
        market_start_time: str,
        market_type: str,
        betting_type: str,
        runner_handicap: str,
        runner_id: str,
        runner_name: str,
        runner_sort_priority: str,
    ):
        self.instrument_id = instrument_id

        # Event Info - Basketball
        self.event_type_id = event_type_id
        self.event_type_name = event_type_name
        self.event_country_code = event_country_code
        self.event_description = event_description
        self.event_open_date = event_open_date
        self.event_timezone = event_timezone

        # Competition - NBA
        self.competition_id = competition_id
        self.competition_name = competition_name

        # Event Name e.g. Utah Jazz @ Boston Celtics Wed 17 Mar, 10:40
        self.event_id = event_id
        self.event_name = event_name

        # Market Info - Match odds / Handicap
        self.betting_type = betting_type
        self.market_id = market_id
        self.market_type = market_type
        self.market_name = market_name
        self.market_start_time = market_start_time

        # Runner info - The selection you're betting on (LA Lakers)
        self.runner_id = runner_id
        self.runner_name = runner_name
        self.runner_handicap = runner_handicap
