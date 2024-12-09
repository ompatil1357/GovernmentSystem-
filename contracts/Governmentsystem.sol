// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract SimplifiedGovernmentTaxSystem {
    // Enums
    enum SpendingStatus {
        Pending,
        Approved,
        Rejected,
        Completed
    }

    enum PaymentStatus {
        Unprocessed,
        Processed
    }

    struct TaxPayment {
        uint256 amount;
        uint32 timestamp;
        PaymentStatus status; // Enum instead of bool
    }

    struct Expenditure {
        uint32 timestamp;
        uint256 amount;
        string purpose;
        SpendingStatus status;
    }

    // State variables
    address public immutable deployedBy;
    address public governmentWallet;
    uint256 public totalCollectedTaxes;
    uint256 public totalSpent;

    // Optimized storage using mappings
    mapping(address => mapping(uint256 => TaxPayment)) private citizenTaxHistory;
    mapping(address => uint256) private citizenTaxCount;
    mapping(uint256 => Expenditure) private expenditures;
    mapping(uint256 => string) private expenditureDetails;
    mapping(address => uint256) private totalTaxPaidByCitizen;

    // Access control
    mapping(address => bool) public authorizedAuditors;

    // Counters
    uint256 private expenditureCount;

    // Events
    event ExpenditureCreated(
        uint256 indexed id,
        uint256 amount,
        uint256 timestamp,
        string purpose,
        SpendingStatus status
    );

    event TaxPaid(
        address indexed citizen,
        uint256 amount,
        uint256 timestamp,
        PaymentStatus status
    );

    event AuditorStatusChanged(
        address indexed auditor,
        bool status,
        uint256 timestamp
    );

    event GovernmentWalletChanged(
        address indexed oldWallet,
        address indexed newWallet,
        uint256 timestamp
    );

    // Custom errors for gas optimization
    error UnauthorizedAccess();
    error InsufficientFunds();
    error InvalidAmount();
    error InvalidAddress();
    error InvalidOperation();

    // Modifiers
    modifier onlyGovernment() {
        if (msg.sender != governmentWallet) revert UnauthorizedAccess();
        _;
    }

    modifier onlyAuditor() {
        if (!authorizedAuditors[msg.sender]) revert UnauthorizedAccess();
        _;
    }

    modifier nonZeroAmount(uint256 amount) {
        if (amount == 0) revert InvalidAmount();
        _;
    }

    constructor() {
        governmentWallet = msg.sender;
        deployedBy = msg.sender;
    }

    function payTax() external payable nonZeroAmount(msg.value) {
        address sender = msg.sender;
        uint256 currentCount = citizenTaxCount[sender];
        uint256 amount = msg.value;
        uint32 timestamp = uint32(block.timestamp);

        citizenTaxHistory[sender][currentCount] = TaxPayment({
            amount: amount,
            timestamp: timestamp,
            status: PaymentStatus.Processed
        });

        citizenTaxCount[sender] = currentCount + 1;
        totalCollectedTaxes += amount;
        totalTaxPaidByCitizen[sender] += amount;

        emit TaxPaid(sender, amount, timestamp, PaymentStatus.Processed);
    }

    function governspendTax(
        address payable recipient,
        uint256 amount,
        string calldata purpose,
        string calldata developmentDetails
    ) external onlyGovernment nonZeroAmount(amount) {
        if (amount > address(this).balance) revert InsufficientFunds();

        uint256 newExpenditureId = expenditureCount;

        expenditures[newExpenditureId] = Expenditure({
            timestamp: uint32(block.timestamp),
            amount: amount,
            purpose: purpose,
            status: SpendingStatus.Completed
        });

        expenditureDetails[newExpenditureId] = developmentDetails;

        expenditureCount++;
        totalSpent += amount;

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert(string(abi.encodePacked("Failed transfer to: ", recipient)));
        }

        emit ExpenditureCreated(
            newExpenditureId,
            amount,
            block.timestamp,
            purpose,
            SpendingStatus.Completed
        );
    }

    function setAuditor(address auditor, bool status) external onlyGovernment {
        if (auditor == address(0)) revert InvalidAddress();
        authorizedAuditors[auditor] = status;

        emit AuditorStatusChanged(auditor, status, block.timestamp);
    }

    function changeGovernmentWallet(address newWallet) external onlyGovernment {
        if (newWallet == address(0)) revert InvalidAddress();
        address oldWallet = governmentWallet;
        governmentWallet = newWallet;

        emit GovernmentWalletChanged(oldWallet, newWallet, block.timestamp);
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTotalTaxPaid(address citizen) external view returns (uint256) {
        return totalTaxPaidByCitizen[citizen];
    }

    function getTaxPayment(address citizen, uint256 index)
        external
        view
        returns (TaxPayment memory)
    {
        return citizenTaxHistory[citizen][index];
    }

    function getExpenditureDetails(uint256 id)
        external
        view
        returns (Expenditure memory exp, string memory details)
    {
        return (expenditures[id], expenditureDetails[id]);
    }

    function getTotalExpenditures() external view returns (uint256) {
        return expenditureCount;
    }
}


  // function getCitizenTaxHistory(
    //     address citizen,
    //     uint256 startIndex,
    //     uint256 limit
    // ) external view returns (TaxPayment[] memory) {
    //     uint256 totalRecords = citizenTaxCount[citizen];

    //     // Fix the return statement for no records
    //     if (startIndex >= totalRecords) return new TaxPayment
    //     uint256 count = (totalRecords - startIndex) < limit
    //         ? (totalRecords - startIndex)
    //         : limit;

    //     // Declare the memory array
    //     TaxPayment[] memory payments = new TaxPayment[](count);

    //     // Loop to populate the array
    //     for (uint256 i = 0; i < count; i++) {
    //         payments[i] = citizenTaxHistory[citizen][startIndex + i];
    //     }

    //     return payments;
    // }