//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

contract KYC{

    /**
     * Customer structure
     */
    struct Customer {
        string userName;   
        string data;  
        bool kycStatus;
        uint256 downvotes;
        uint256 upvotes;
        address bank;
    }
    
    /**
     * Bank Structure
     */
    struct Bank {
        string name;
        address ethAddress;
        uint256 complaintsReported;
        uint256 kycCount;
        bool isAllowedToVote;
        string regNumber;
    }

    /**
     * KYC Request Structure
     */
    struct KycRequest {
        string userName;
        address bankAddress;
        string data;
    }


    address public admin; // Stores the admin's address
    mapping(string => Customer) customers; //mapping of customers in the blockchain
    mapping(address => Bank) banks; //mapping of banks in the blockchain
    mapping(string => KycRequest) requests; //mapping of KYC requests in the blockchain
    uint256 public numberOfBanks; //number of banks in the network

    event Log(string message); //LOG event function

    constructor(){
        admin = msg.sender;
        numberOfBanks = 0;
    }

    /**
     * Modifier to check for admin
     */
    modifier onlyAdmin(){
        require(msg.sender == admin, "Requester is not Admin");
        _;
    }

    /**
     * Modifier to check for banks
     */
    modifier onlyBanks(){
        require(banks[msg.sender].ethAddress != address(0), "Requester is not a Bank");
        _;
    }

    /**
     * Modifier to check if customer is present in the blockchain
     */
    modifier customerPresent(string memory _userName) {
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        _;
    }

    /**
     * Modifier to check if bank is present in the blockchain
     */
    modifier bankPresent(address _bankAddress) {
        require(banks[_bankAddress].ethAddress != address(0), "Bank is not present in the database");
        _;
    }

    /**
     * Modifier to validate the bank
     * Checks if the bank is allowed to vote
     */
    modifier validBank() {
        require(banks[msg.sender].isAllowedToVote == true, "Bank is not credible for this operation");
        _;
    }

    /**
     * Funtion to add a bank 
     * Can be executed only by admin
     */
    function addBank(string memory _bankName, address _bankAddress, string memory _regNumber) public onlyAdmin {
        banks[_bankAddress].name = _bankName;
        banks[_bankAddress].ethAddress = _bankAddress;
        banks[_bankAddress].regNumber = _regNumber;
        banks[_bankAddress].kycCount = 0;
        banks[_bankAddress].isAllowedToVote = false;
        banks[_bankAddress].complaintsReported = 0;

        numberOfBanks++;
    }

    /**
     * Funtion to modify the permission to vote
     * Can be executed only by admin
     */
    function modifyPermissionToVote(address _bankAddress, bool _isAllowedToVote) public onlyAdmin bankPresent(_bankAddress) {
        banks[_bankAddress].isAllowedToVote = _isAllowedToVote;
    }

    /**
     * Funtion to remove the bank from the blockchain
     * Can be executed only by admin
     */
    function removeBank(address _bankAddress) public onlyAdmin bankPresent(_bankAddress) {
        delete banks[_bankAddress];
    }

    /**
     * Funtion to add a KYC request
     * Can be executed only by banks
     */
    function addRequest(string memory _customerName, string memory _customerData) public onlyBanks {
        require(requests[_customerData].bankAddress != address(0), "KYC request is already requested for the customer");
        requests[_customerName].userName = _customerName;
        requests[_customerName].data = _customerData;
        requests[_customerName].bankAddress = msg.sender;

        banks[msg.sender].kycCount++;
    }

    /**
     * Funtion to add a customer in the network
     * Can be executed only by valid banks
     */
    function addCustomer(string memory _userName, string memory _customerData) public onlyBanks validBank {
        require(customers[_userName].bank == address(0), "Customer is already present, please call modifyCustomer to edit the customer data");
        customers[_userName].userName = _userName;
        customers[_userName].data = _customerData;
        customers[_userName].bank = msg.sender;
        customers[_userName].kycStatus = false;
        customers[_userName].upvotes = 0;
        customers[_userName].downvotes = 0;
    }

    /**
     * Funtion to remove the KYC request from the blockchain
     * Can be executed by only the banks
     */
    function removeRequest(string memory _userName) public onlyBanks validBank customerPresent(_userName) {
        delete customers[_userName];
    }
    
    /**
     * Funtion to view customer details
     * Can be executed by the banks
     */
    function viewCustomer(string memory _userName) public onlyBanks validBank customerPresent(_userName) view returns (string memory, string memory, bool, uint256, uint256, address) {
        return (customers[_userName].userName,
                 customers[_userName].data,
                 customers[_userName].kycStatus, 
                 customers[_userName].upvotes, 
                 customers[_userName].downvotes, 
                 customers[_userName].bank);
    }

    /**
     * Funtion to upvote customer details
     * Can be executed by the banks
     */
    function upvoteCustomers(string memory _userName) public onlyBanks validBank customerPresent(_userName) {
        customers[_userName].upvotes++;

        uint256 upvotes = customers[_userName].upvotes;
        uint256 downvotes = customers[_userName].downvotes;
        if(upvotes > downvotes) {
            customers[_userName].kycStatus = true;
        }
        uint256 oneThirdBanks = (numberOfBanks) / 3;
        if(downvotes > oneThirdBanks) {
            customers[_userName].kycStatus = false;
        }
    }

    /**
     * Funtion to downvote customers
     * Can be executed only by the banks
     */
    function downvoteCustomers(string memory _userName) public onlyBanks validBank customerPresent(_userName) {
        customers[_userName].downvotes++;

        uint256 upvotes = customers[_userName].upvotes;
        uint256 downvotes = customers[_userName].downvotes;
        if(upvotes > downvotes) {
            customers[_userName].kycStatus = true;
        }
        uint256 oneThirdBanks = (numberOfBanks)/3;
        if(downvotes > oneThirdBanks) {
            customers[_userName].kycStatus = false;
        }
    }
    
    /**
     * Funtion to modify customers
     * Can be executed only by the valid banks
     */
    function modifyCustomer(string memory _userName, string memory _newcustomerData) public onlyBanks validBank customerPresent(_userName) {
        customers[_userName].data = _newcustomerData;
        customers[_userName].downvotes = 0;
        customers[_userName].upvotes = 0;
        customers[_userName].kycStatus = false;
        delete requests[_userName];
    }    

    /**
     * Funtion to view Bank complaints 
     * Can be viewed pnly by the banks
     */
    function getBankComplaints(address _bankAddress) public onlyBanks bankPresent(_bankAddress) view returns (uint256) {
        return banks[_bankAddress].complaintsReported;
    }

    /**
     * Function to view Bank Details 
     * Can be viewed only by the banks
     */
    function viewBankDetails(address _bankAddress) public onlyBanks bankPresent(_bankAddress) view returns (Bank memory) {
        return banks[_bankAddress];
    }
    
    /**
     * Function to report bank
     * Can be executed by other banks in the blockchain network
     */
    function reportBank(address _bankAddress, string memory _bankName) public onlyBanks bankPresent(_bankAddress) {
        emit Log(_bankName);
        banks[_bankAddress].complaintsReported++;

        uint256 complaints = this.getBankComplaints(_bankAddress);
        uint256 oneThirdBanks = (numberOfBanks)/3;
        if(complaints > oneThirdBanks){
            banks[_bankAddress].isAllowedToVote = false;
        }
    }
    
}    


