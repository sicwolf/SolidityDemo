// SPDX-License-Identifier: MIT
// Custom Error handling demo.
// Water Wang created in 2022/8/30.

pragma solidity ^0.8.16;
import "@openzeppelin/contracts/utils/Strings.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

error NoPermission(address owner, address caller);

contract CalleeContract {
    // Owner of this contract, means that who deployed this contract.
    address owner;
    // The times that contract called.
    uint8 calledTimes = 0;

    constructor () {
        // Record the owner who creates this contract.
        owner = msg.sender;
    }

    function callContract(address caller) public returns (uint8) {
        // If the caller is not the owner, reverts NoPermission exception.
        if (caller != owner)
            revert NoPermission(owner, caller);

        // If the caller is the owner, returns call times.
        calledTimes++;
        return calledTimes;
    }
}

contract CallerContract {
    // Contract to be called.
    CalleeContract calleeContract;

    constructor (address calleeContractAddress) {
        // Stores the contract to be called.
        calleeContract = CalleeContract(calleeContractAddress);
    }

    // Encode the instance of custom error NoPermission(address,address) and return encoded data.
    // It demonstrates that Solidity uses abi.encodeWithSignature function to encode custom error instance.
    function encodeCustomError() public pure returns (bytes memory encodedData) {
        encodedData = abi.encodeWithSignature(
            "NoPermission(address,address)", 
            // The address of External Owned Account who creates CalleeContract.
            address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4), 
            // The address of External Owned Account who creates and calls CallerContract.
            address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2)
        );
    }

    function callContract() public returns (string memory returnString, bytes memory encodedErrorData) {
        // Call callee contract's function with the address of External Owned Account.
        try calleeContract.callContract(msg.sender) returns (uint8 calledTimes) {
            returnString = string.concat("Success: calledTimes = ", Strings.toString(calledTimes));
        // catch custom error exception
        } catch (bytes memory lowLevelData) {
            bytes4 selector = bytes4(lowLevelData);
            address owner;
            address caller;
            encodedErrorData = lowLevelData;

            // Step 1: Compare the first 4 bytes in lowlevel data and the seclector of NoPermission
            if (selector == NoPermission.selector) {
                // If they are equal, then continue follwing decode.
                // Step 2: decode following 32 bytes in lowlevel data as 20-byte address.
                owner = address(uint160(uint256(bytes32(BytesLib.slice(lowLevelData, 4, 32)))));
                // Step 3: decode oncemore following 32 bytes in lowlevel data as 20-byte address.
                caller = address(uint160(uint256(bytes32(BytesLib.slice(lowLevelData, 36, 32)))));
                returnString = string.concat(
                    "Failed: NoPermission owner = ", 
                    Strings.toHexString(owner), 
                    " caller = ", 
                    Strings.toHexString(caller)
                    );
            } else {
                // Else, the exception is not the error type we care.
                returnString = "Failed: Other error";
            }
        }
    }
}
