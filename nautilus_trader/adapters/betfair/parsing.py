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
import datetime

from model.instrument import BettingInstrument


VENUE = "betfair"


def filter_type(root, filter_value):
    for child in root["children"]:
        if child["type"] == filter_value:
            yield child
        elif "children" in child:
            yield from filter_type(child, filter_value)


def flatten_tree(dict_like, **filters):
    ignore_keys = ("type", "children")
    node_type = dict_like["name"].lower()
    data = {f"{node_type}_{k}": v for k, v in dict_like.items() if k not in ignore_keys}
    for child in dict_like.get("children", []):
        yield {**data, **flatten_tree(child, **filters)}


def load_markets(client, filter=None):
    navigation = client.navigation.list_navigation()
    return list(flatten_tree(navigation, **(filter or {})))


# def load_instruments(client, markets):
#     # cdef str k
#     # cdef dict v
#     # cdef InstrumentId instrument_id
#     # cdef Instrument instrument
#     navigation = client.navigation.list_navigation()
#     for parsed in map(parse_market_definition, flatten_tree(navigation)):
#         pass
#         # instrument_id = InstrumentId(Symbol(k), self.venue)
#         # instrument = self._parse_instrument(instrument_id, v)
#         # if instrument is None:
#         #     continue  # Something went wrong in parsing
#         # self._instruments[instrument_id] = instrument


def make_instrument(values):
    def make_instrument_id():
        return f"{values['event_type']}"

    return BettingInstrument(
        instrument_id=make_instrument_id(),
        competition_id=values["competition_id"],
        competition_name=values["competition_name"],
        event_country_code=values["event_country_code"],
        event_description=values["event_description"],
        event_id=values["event_id"],
        event_name=values["event_name"],
        event_open_date=values["event_open_date"],
        event_timezone=values["event_timezone"],
        event_type_id=values["event_type_id"],
        event_type_name=values["event_type_name"],
        market_id=values["market_id"],
        market_name=values["market_name"],
        market_start_time=values["market_start_time"],
        market_type=values["market_type"],
        betting_type=values["betting_type"],
        selection_id=values["selection_id"],
        selection_name=values["selection_name"],
        selection_handicap=values["selection_handicap"],
        timestamp=datetime.datetime.utcnow(),
        info=values,
    )


def search(root, *terms):
    level_search, remaining_terms = terms[0], terms[1:]
    for child in root["children"]:
        if level_search.lower() in child["name"].lower():
            if not len(remaining_terms):
                yield child
            elif "children" in child:
                yield from search(child, *remaining_terms)


# def filter_markets(nav_results, *search_terms):
#     category = next(search(nav_results, *search_terms))
#     listed_games = filter_type(category, "EVENT")
#     game_markets = filter_type({"children": listed_games}, "MARKET")
