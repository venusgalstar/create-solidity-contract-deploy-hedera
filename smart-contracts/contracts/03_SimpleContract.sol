// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract SimpleContract {
    uint64 private _counter;

    constructor(uint64 counter_) {
        _counter = counter_;
    }

    function updateCaller() public {
        _counter = _counter + 1;
    }

    function getCounter() public view returns (uint64) {
        return _counter;
    }
}
