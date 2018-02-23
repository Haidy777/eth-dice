pragma solidity 0.4.20;

contract zeroOrOne {
    uint private initialNonce = 2;
    uint8 private counter = 1;

    function randFromLastBlocks() internal returns (uint) {
        counter++;
        initialNonce = minMax((block.timestamp + block.difficulty + block.gaslimit + block.number + counter), 2, 255);

        if (counter > 255) {
            counter = 1;
        }

        uint rnd1 = uint(block.blockhash(block.number - minMax(uint(block.blockhash(block.number - initialNonce)), 2, 255)));
        uint rnd2 = uint(block.blockhash(block.number - counter));
        uint rnd3 = initialNonce / counter;

        //pretty costly calculation (more than 200000 gas)
        //        uint startingBlock = block.number - minMax(uint(block.blockhash(block.number - initialNonce)), 2, 255);
        //        uint blocksToConsider = minMax(uint(block.blockhash(block.number - counter)), 0, startingBlock - 1);
        //pseudo random numbers of blocks which will be used to calculate a pseudo random number

        //        uint randomNumber = 0;

        //        for (uint i = 0; i <= blocksToConsider; i++) {
        //            uint currentNumber = uint(block.blockhash(startingBlock + i));
        //
        //            randomNumber += currentNumber;
        //could there be a out of memory problem?
        //        }

        return (rnd1 - rnd2) + rnd3;
    }

    function minMax(uint no, uint min, uint max) internal pure returns (uint) {
        return no % (min + max) - min;
    }

    function rand() public returns (uint) {
        return minMax(randFromLastBlocks(), 0, 10);
    }
}

contract DiceContract {
    zeroOrOne zoO = new zeroOrOne();
    address private owner = msg.sender;
    uint private collectedFees = 0;
    mapping(address => uint) private kindDonators;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function DiceContract() public payable {}

    function roll() public payable {
        uint value = msg.value;

        require(value * 2 < this.balance);

        uint willWin = zoO.rand();

        if (willWin >= 5) {
            uint winAmount = value * 2;
            uint onePercent = winAmount / 100;

            // if the sender wins he gets almost double his bet
            // 1 percent is taken for the contract developer
            // 1 percent is submitted to the contract itself for liquidity
            collectedFees += onePercent;
            msg.sender.transfer(winAmount - (onePercent * 2));
        }
    }

    function donateForGamble() public payable {
        kindDonators[msg.sender] += msg.value;
    }

    function getBackDonation() public {
        uint donationAmount = kindDonators[msg.sender];

        require(donationAmount != 0 && collectedFees > 0);

        kindDonators[msg.sender] = 0;

        msg.sender.transfer(donationAmount + (collectedFees / 100));
        // every donator gets a bonus when he gets his donation back
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