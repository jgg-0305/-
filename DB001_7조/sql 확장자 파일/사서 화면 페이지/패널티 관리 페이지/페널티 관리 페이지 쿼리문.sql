USE library_system;
-- -----------------------------------------------------
-- 1. [회원 조회] 기본 정보 및 현재 상태 (블랙리스트 여부)
-- -----------------------------------------------------
-- 화면 상단 '조기강 (20233849)' 카드 정보
SELECT
    T1.usr_id       AS 학번,
    T1.usr_name     AS 이름,
    T1.usr_dept     AS 학과,
    T1.usr_phone    AS 연락처,
    T1.usr_stat     AS 회원상태, -- (정상/정지/졸업)
    
    -- 현재 적용 중인 제재가 있는지 확인 (화면의 'BLACK LIST' 뱃지용)
    (SELECT EXISTS(
        SELECT 1 FROM penalties 
        WHERE usr_id = T1.usr_id AND pnl_actv = 1 AND pnl_end >= CURDATE()
    )) AS 제재_적용_여부,
    
    -- 현재 연체 중인 도서 권수 (화면: '2권')
    (SELECT COUNT(*) FROM loans 
     WHERE usr_id = T1.usr_id AND loan_ret IS NULL AND loan_due < CURDATE()) AS 연체_도서_수
FROM
    users T1
WHERE
    T1.usr_id = 20233849; -- [변수] 검색창 입력값 (학번)


-- -----------------------------------------------------
-- 2. [계산] 실시간 패널티 시뮬레이션 (Calc Box)
-- -----------------------------------------------------
-- 화면 중간 '패널티 계산' 박스에 들어갈 데이터
SELECT
    T3.bk_title     AS 연체_도서명,
    T1.loan_due     AS 반납_예정일,
    DATEDIFF(CURDATE(), T1.loan_due) AS 연체일수, -- (오늘 - 예정일)
    
    -- 예상 정지 일수 계산 (규정: 연체일수 * 1일 정지 라고 가정 시)
    -- 화면 로직(2배)에 맞춘다면 * 2
    (DATEDIFF(CURDATE(), T1.loan_due) * 1) AS 예상_정지일
FROM
    loans T1
JOIN 
    book_copies T2 ON T1.cbk_id = T2.cbk_id
JOIN 
    books T3 ON T2.bk_id = T3.bk_id
WHERE
    T1.usr_id = 20233849           -- [변수] 학번
    AND T1.loan_ret IS NULL  -- 미반납
    AND T1.loan_due < CURDATE(); -- 연체됨


-- -----------------------------------------------------
-- 3. [리스트] 제재 이력 조회 (History Table)
-- -----------------------------------------------------
-- 화면 하단 테이블 데이터
SELECT
    pnl_id          AS No,
    pnl_type        AS 위반_유형,   -- (연체, 분실, 파손 등)
    pnl_reason      AS 상세_사유,   -- (도서명 등)
    DATE_FORMAT(pnl_start, '%Y-%m-%d') AS 시작일,
    DATE_FORMAT(pnl_end, '%Y-%m-%d')   AS 종료일,
    
    -- 상태 표시 로직
    CASE
        WHEN pnl_actv = 1 AND pnl_end >= CURDATE() THEN '적용 중'
        ELSE '종료됨'
    END AS 상태
FROM
    penalties
WHERE
    usr_id = 20233849      -- [변수] 학번
ORDER BY
    pnl_start DESC;


-- -----------------------------------------------------
-- 4. [액션] 제재 강제 해제 (버튼 클릭)
-- -----------------------------------------------------
-- 화면의 '제재 강제 해제' 버튼 클릭 시 실행
-- 1) 패널티 테이블 비활성화 처리
UPDATE penalties
SET
    pnl_actv = 0, -- 비활성화
    pnl_reason = CONCAT(pnl_reason, ' / (사서 강제 해제)') -- 사유 기록
WHERE
    usr_id = 20233849    -- [변수] 학번
    AND pnl_actv = 1 
    AND pnl_end >= CURDATE();

-- 2) 유저 상태 '정상'으로 복구
UPDATE users
SET usr_stat = '정상'
WHERE usr_id = 20233849;


-- -----------------------------------------------------
-- 5. [액션] 제재 이력 수정 (테이블 내 수정 버튼)
-- -----------------------------------------------------
-- 하단 리스트의 작은 '수정' 버튼 클릭 시 (종료일 변경 등)
UPDATE penalties
SET
    pnl_end = '2026-03-31',    -- [변수] 변경할 종료일
    pnl_reason = '장기간 도서 연체로 인한 패널티 기간 연장'  -- [변수] 변경할 사유
WHERE
    pnl_id = 10;     -- [변수] 패널티 ID (PK)


