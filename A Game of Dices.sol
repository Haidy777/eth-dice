pragma solidity 0.4.20;

contract zeroOrOne {
    uint private initialNonce = 2;

    function randFromLastBlocks() internal returns (uint){
        initialNonce = minMax(block.timestamp, 2, 255);
        //change the initialNonce based on the current blockTimestamp

        uint blocksToConsider = minMax(uint(block.blockhash(block.number - initialNonce)), 2, 255);
        //pseudeo random number of blocks which will be used to calculate a pseudorandom number
        uint randomNumber = 0;

        for (uint i = 0; i <= blocksToConsider; i++) {
            uint currentNumber = uint(block.blockhash(block.number - i));

            randomNumber += currentNumber;
            //could there be a out of memory problem?
        }

        return randomNumber;
    }

    function minMax(uint no, uint min, uint max) internal pure returns (uint) {
        return no % (min + max) - min;
    }

    function main() public returns (uint) {
        return minMax(randFromLastBlocks(), 0, 1);
    }
}

contract dice {
    //https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol#L25
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    zeroOrOne zoO = new zeroOrOne();
    address owner = msg.sender;
    uint collectedFees = 0;

    function roll() public payable {
        uint value = msg.value;

        if (value * 2 < this.balance) {
            uint willWin = zoO.main();

            if (willWin == 1) {
                uint winAmount = value * 2;
                uint onePercent = div(winAmount, 100);

                // if the sender wins he gets almost double his bet
                // 1 percent is taken for the contract developer
                // 1 percent is submitted to the contract itself for liquidity
                collectedFees += onePercent;
                msg.sender.transfer(winAmount - (onePercent * 2));
            }
        } else {
            revert();
        }
    }

    function preloadContract() public payable returns (string) {
        return "Thanks for providing funds to gamble!";
    }

    function getFeeBalance() public view returns (uint){
        return collectedFees;
    }

    function collectFees() public {
        if (msg.sender == owner) {
            uint colFees = collectedFees;

            collectedFees = 0;

            msg.sender.transfer(colFees);
        } else {
            revert();
        }
    }

    function itsTimeToDie() public {
        if (msg.sender == owner) {
            selfdestruct(owner);
        }
    }
}