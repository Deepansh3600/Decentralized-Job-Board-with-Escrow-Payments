// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DecentralizedJobBoard {
    struct Job {
        uint256 id;
        address payable employer;
        string description;
        uint256 payment;
        address payable worker;
        bool isCompleted;
        bool isFunded;
    }

    uint256 public jobCounter;
    mapping(uint256 => Job) public jobs;

    event JobPosted(uint256 indexed jobId, address indexed employer, uint256 payment, string description);
    event JobFunded(uint256 indexed jobId);
    event JobAccepted(uint256 indexed jobId, address indexed worker);
    event JobCompleted(uint256 indexed jobId);
    event PaymentReleased(uint256 indexed jobId, address indexed worker, uint256 amount);
    event JobCancelled(uint256 indexed jobId);

    modifier onlyEmployer(uint256 _jobId) {
        require(jobs[_jobId].employer == msg.sender, "Not employer");
        _;
    }

    modifier onlyWorker(uint256 _jobId) {
        require(jobs[_jobId].worker == msg.sender, "Not assigned worker");
        _;
    }

    function postJob(string calldata _description, uint256 _payment) external returns (uint256) {
        require(_payment > 0, "Payment must be > 0");

        jobCounter++;
        jobs[jobCounter] = Job({
            id: jobCounter,
            employer: payable(msg.sender),
            description: _description,
            payment: _payment,
            worker: payable(address(0)),
            isCompleted: false,
            isFunded: false
        });

        emit JobPosted(jobCounter, msg.sender, _payment, _description);
        return jobCounter;
    }

    function fundJob(uint256 _jobId) external payable onlyEmployer(_jobId) {
        Job storage job = jobs[_jobId];
        require(!job.isFunded, "Already funded");
        require(msg.value == job.payment, "Incorrect funding amount");

        job.isFunded = true;
        emit JobFunded(_jobId);
    }

    function acceptJob(uint256 _jobId) external {
        Job storage job = jobs[_jobId];
        require(job.worker == address(0), "Job already accepted");
        require(job.isFunded, "Job not funded");
        require(!job.isCompleted, "Job already completed");

        job.worker = payable(msg.sender);
        emit JobAccepted(_jobId, msg.sender);
    }

    function markCompleted(uint256 _jobId) external onlyWorker(_jobId) {
        Job storage job = jobs[_jobId];
        require(!job.isCompleted, "Already completed");

        job.isCompleted = true;
        emit JobCompleted(_jobId);
    }

    function releasePayment(uint256 _jobId) external onlyEmployer(_jobId) {
        Job storage job = jobs[_jobId];
        require(job.isCompleted, "Job not completed");
        require(job.isFunded, "Job not funded");

        uint256 paymentAmount = job.payment;
        job.payment = 0;
        job.isFunded = false;

        (bool sent, ) = job.worker.call{value: paymentAmount}("");
        require(sent, "Payment transfer failed");

        emit PaymentReleased(_jobId, job.worker, paymentAmount);
    }

    function cancelJob(uint256 _jobId) external onlyEmployer(_jobId) {
        Job storage job = jobs[_jobId];
        require(!job.isFunded || !job.isCompleted, "Cannot cancel funded or completed job");

        if (job.isFunded) {
            uint256 refundAmount = job.payment;
            job.payment = 0;
            job.isFunded = false;
            (bool refunded, ) = job.employer.call{value: refundAmount}("");
            require(refunded, "Refund failed");
        }

        delete jobs[_jobId];
        emit JobCancelled(_jobId);
    }

    function getJob(uint256 _jobId) external view returns (
        uint256 id,
        address employer,
        string memory description,
        uint256 payment,
        address worker,
        bool isCompleted,
        bool isFunded
    ) {
        Job storage job = jobs[_jobId];
        return (
            job.id,
            job.employer,
            job.description,
            job.payment,
            job.worker,
            job.isCompleted,
            job.isFunded
        );
    }
}
