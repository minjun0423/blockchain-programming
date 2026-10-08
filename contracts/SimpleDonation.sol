// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleDonation {

    // =========================================================
    // 1. 역할(Role) 관련 상태 변수
    // =========================================================

    // 기존
    // 컨트랙트를 관리하는 운영자 주소
    address public owner;

    // ★ NEW
    // 실제 기부금을 출금할 수 있는 수혜자 주소
    // payable이 붙은 이유:
    // 이 주소로 ETH를 실제 전송할 예정이기 때문
    address payable public beneficiary;


    // =========================================================
    // 2. 캠페인 상태 및 기부 데이터
    // =========================================================

    // 기존
    // true  = 기부 가능
    // false = 기부 중단
    bool public campaignActive;

    // 기존
    // 지금까지 받은 전체 누적 기부액
    // 출금하더라도 이 값은 줄어들지 않음
    uint256 public totalDonated;

    // 기존
    // 각 지갑 주소별 누적 기부액 저장
    mapping(address => uint256) public donations;


    // =========================================================
    // 3. 재진입 공격 방지용 변수
    // =========================================================

    // ★ NEW
    // withdraw()가 실행 중인지 확인하기 위한 잠금 변수
    //
    // false = 출금 함수 실행 중 아님
    // true  = 출금 함수 실행 중
    //
    // 외부 주소로 ETH를 보내는 과정에서
    // withdraw()가 다시 호출되는 것을 막기 위해 사용
    bool private locked;


    // =========================================================
    // 4. 이벤트(Event)
    // =========================================================

    // 기존
    // 기부 발생 기록
    event Donated(
        address indexed donor,
        uint256 amount
    );

    // 기존
    // 캠페인 활성/중단 상태 변경 기록
    event CampaignStatusChanged(
        bool active
    );

    // ★ NEW
    // 출금이 발생했을 때 기록
    event Withdrawn(
        address indexed beneficiary,
        uint256 amount
    );

    // ★ NEW
    // 수혜자 주소가 변경됐을 때 기록
    event BeneficiaryChanged(
        address indexed oldBeneficiary,
        address indexed newBeneficiary
    );


    // =========================================================
    // 5. constructor
    // =========================================================

    // ★ CHANGED
    //
    // 이전에는:
    //
    // owner = msg.sender;
    // beneficiary = payable(msg.sender);
    //
    // 로 되어 있어서 운영자와 수혜자가 같은 계정으로 시작했음.
    //
    // 이제는 배포할 때 수혜자 주소를 별도로 입력하도록 변경.
    //
    // 예:
    //
    // Account 1로 Deploy
    // → owner = Account 1
    //
    // Deploy 입력란에 Account 2 주소 입력
    // → beneficiary = Account 2
    //
    constructor(address payable initialBeneficiary) {

        // 컨트랙트를 배포한 사람이 운영자가 됨
        owner = msg.sender;

        // ★ NEW
        // 0x000... 주소를 수혜자로 등록하는 실수를 방지
        require(
            initialBeneficiary != address(0),
            "Invalid beneficiary address"
        );

        // 배포할 때 입력한 주소를 수혜자로 지정
        beneficiary = initialBeneficiary;

        // 캠페인은 처음부터 활성 상태
        campaignActive = true;
    }


    // =========================================================
    // 6. modifier - 운영자 권한 확인
    // =========================================================

    // 기존
    modifier onlyOwner() {

        require(
            msg.sender == owner,
            "Only owner can call this function"
        );

        _;
    }


    // =========================================================
    // 7. modifier - 수혜자 권한 확인
    // =========================================================

    // ★ NEW
    //
    // withdraw()는 beneficiary만 실행 가능
    //
    modifier onlyBeneficiary() {

        require(
            msg.sender == beneficiary,
            "Only beneficiary can call this function"
        );

        _;
    }


    // =========================================================
    // 8. modifier - 재진입 공격 방지
    // =========================================================

    // ★ NEW
    modifier nonReentrant() {

        // 이미 withdraw()가 실행 중이라면 거부
        require(
            !locked,
            "Reentrant call"
        );

        // 함수 실행 전에 잠금
        locked = true;

        // 실제 withdraw() 본문 실행
        _;

        // 함수가 끝나면 잠금 해제
        locked = false;
    }


    // =========================================================
    // 9. ETH 기부
    // =========================================================

    // 기존
    function donate() external payable {

        // 캠페인이 활성 상태인지 확인
        require(
            campaignActive,
            "Campaign is not active"
        );

        // 0 ETH 기부 방지
        require(
            msg.value > 0,
            "Donation must be greater than zero"
        );

        // 현재 기부자의 누적 기부액 증가
        donations[msg.sender] += msg.value;

        // 전체 누적 기부액 증가
        totalDonated += msg.value;

        // 기부 기록 남김
        emit Donated(
            msg.sender,
            msg.value
        );
    }


    // =========================================================
    // 10. 캠페인 활성화 / 중단
    // =========================================================

    // 기존
    //
    // owner만 실행 가능
    //
    function setCampaignActive(
        bool active
    )
        external
        onlyOwner
    {
        campaignActive = active;

        emit CampaignStatusChanged(
            active
        );
    }


    // =========================================================
    // 11. 수혜자 주소 변경
    // =========================================================

    // ★ NEW
    //
    // 운영자가 수혜자 주소를 변경할 수 있음.
    //
    // 단,
    // 이미 컨트랙트에 기부금이 들어온 상태에서는
    // 수혜자를 바꾸지 못하도록 제한.
    //
    function changeBeneficiary(
        address payable newBeneficiary
    )
        external
        onlyOwner
    {

        // 잘못된 주소 방지
        require(
            newBeneficiary != address(0),
            "Invalid beneficiary address"
        );

        // ★ 중요한 안전 규칙
        //
        // 이미 돈이 들어와 있는 상태에서
        // 운영자가 임의로 수혜자를 바꾸는 것을 방지
        require(
            address(this).balance == 0,
            "Contract balance must be zero"
        );

        // 기존 수혜자 주소 기억
        address oldBeneficiary = beneficiary;

        // 새 수혜자 저장
        beneficiary = newBeneficiary;

        // 변경 내역 기록
        emit BeneficiaryChanged(
            oldBeneficiary,
            newBeneficiary
        );
    }


    // =========================================================
    // 12. 기부금 출금
    // =========================================================

    // ★ NEW
    //
    // beneficiary만 실행 가능
    // 재진입 공격 방지 적용
    //
    function withdraw()
        external
        onlyBeneficiary
        nonReentrant
    {

        // 현재 컨트랙트가 가지고 있는 ETH 잔액
        uint256 balance = address(this).balance;

        // 출금할 돈이 없다면 실행 중단
        require(
            balance > 0,
            "No balance to withdraw"
        );

        // 컨트랙트에 있는 ETH를
        // beneficiary 주소로 전송
        (bool success, ) = beneficiary.call{
            value: balance
        }("");

        // ETH 전송 실패 시 전체 트랜잭션 취소
        require(
            success,
            "Withdrawal failed"
        );

        // 출금 내역 기록
        emit Withdrawn(
            beneficiary,
            balance
        );
    }


    // =========================================================
    // 13. 전체 누적 기부액 조회
    // =========================================================

    // 기존
    //
    // Solidity 내부에서는 wei로 저장하지만
    // 학습 편의를 위해 ETH 정수 단위로 반환
    //
    function getTotalDonatedInEther()
        external
        view
        returns (uint256)
    {
        return totalDonated / 1 ether;
    }


    // =========================================================
    // 14. 현재 계정의 누적 기부액 조회
    // =========================================================

    // 기존
    function getMyDonationInEther()
        external
        view
        returns (uint256)
    {
        return donations[msg.sender] / 1 ether;
    }


    // =========================================================
    // 15. 현재 컨트랙트 잔액 조회
    // =========================================================

    // ★ NEW
    //
    // totalDonated와 다른 개념임.
    //
    // totalDonated
    // → 지금까지 들어온 역사적 누적 기부액
    //
    // address(this).balance
    // → 현재 컨트랙트에 실제로 남아 있는 ETH
    //
    function getContractBalanceInEther()
        external
        view
        returns (uint256)
    {
        return address(this).balance / 1 ether;
    }
}