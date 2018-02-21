pragma solidity 0.4.20;

contract zeroOrOne {
    uint private initialNonce = 2;
    uint private counter = 0;

    function randFromLastBlocks() internal returns (uint) {
        counter++;
        initialNonce = minMax((block.timestamp + block.difficulty + block.gaslimit + block.number + counter), 2, 255);

        if (counter > 777) {
            counter = 0;
        }

        uint blocksToConsider = minMax(uint(block.blockhash(block.number - initialNonce)), 2, 255);
        //pseudo random number of blocks which will be used to calculate a pseudo random number
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
    address private owner = msg.sender;
    uint private collectedFees = 0;
    mapping(address => uint) private kindDonators;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

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

    function donateForGamble() public payable returns (string) {
        kindDonators[msg.sender] += msg.value;
        return "Thanks for providing funds to gamble!";
    }

    function getBackDonation() {
        uint donationAmount = kindDonators[msg.sender];

        if (donationAmount != 0 && collectedFees > 0) {
            kindDonators[msg.sender] = 0;

            msg.sender.transfer(donationAmount + div(collectedFees / 100)); // every donator gets a bonus when he gets his donation back
        }
    }

    function getFeeBalance() public view returns (uint){
        return collectedFees;
    }

    function collectFees() public onlyOwner {
        uint colFees = collectedFees;

        collectedFees = 0;

        msg.sender.transfer(colFees);
    }

    function itsTimeToDie() public onlyOwner {
        selfdestruct(owner);
    }
}