// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract DummyContract {
    uint64 counter = 0;

    function updateCaller() public {
        counter = counter + 1;
    }
}
