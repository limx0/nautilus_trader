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
import json

import pytest

from adapters.betfair.parsing import load_instruments
from adapters.betfair.parsing import load_markets
from nautilus_trader.adapters.betfair.providers import BetfairInstrumentProvider
from tests import TESTS_PACKAGE_ROOT


TEST_PATH = TESTS_PACKAGE_ROOT + "/integration_tests/adapters/betfair/responses/"


@pytest.fixture()
def provider(mocker, betfair_client) -> BetfairInstrumentProvider:
    # TODO Mock client login
    mock_list_nav = mocker.patch(
        "betfairlightweight.endpoints.navigation.Navigation.list_navigation"
    )
    mock_list_nav.return_value = json.loads(open("./responses/navigation.json").read())
    return BetfairInstrumentProvider(client=betfair_client)


def test_load_markets(provider, betfair_client):
    # provider.load_instruments()
    # markets = load_markets(betfair_client)
    # assert len(markets) == 3303282

    markets = load_markets(betfair_client, filter={"competition": "NBA"})
    assert len(markets) == 3303282


def test_load_instruments(provider, betfair_client):
    # provider.load_instruments()
    load_instruments(betfair_client)


def test_load_all(provider):
    provider.load_all()


def test_search_instruments(provider):
    # instruments = provider.search()
    pass
