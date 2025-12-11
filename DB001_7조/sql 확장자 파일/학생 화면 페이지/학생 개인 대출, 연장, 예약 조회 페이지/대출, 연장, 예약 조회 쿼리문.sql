USE library_system;
-- -----------------------------------------------------
-- 1. [헤더/대시보드] 사용자 요약 정보 조회
-- -----------------------------------------------------

-- 1-1. 사용자 기본 정보 (이름, 학과, 상태)
SELECT 
    usr_id, 
    usr_name, 
    usr_dept,   -- 학과
    usr_stat    -- 상태 (정상/정지/졸업)
FROM 
    users 
WHERE 
    usr_id = 20233849; -- [변수] 로그인한 학번

-- 1-2. 현재 대출 중인 권수
SELECT COUNT(*) AS val_loans
FROM loans 
WHERE usr_id = 20233849 
  AND loan_ret IS NULL; -- 반납일이 없는 것 = 대출 중

-- 1-3. 현재 예약 중인 권수
SELECT COUNT(*) AS val_reservations
FROM reservations 
WHERE usr_id = 20233849 
  AND resv_stat IN ('대기중', '수령가능'); -- [ENUM 체크] DDL 값 일치


-- -----------------------------------------------------
-- 2. [리스트] 대출 현황 조회 (연장 기능 포함)
-- -----------------------------------------------------
SELECT 
    L.loan_id,              -- (Hidden) 연장 처리용 ID
    C.cbk_id AS 등록번호,     -- 도서 등록번호
    B.bk_title AS 서명,      -- 책 제목
    L.loan_date AS 대출일,
    L.loan_due AS 반납예정일,
    
    -- 연장 가능 여부 판단 (DB의 loan_ext가 0/False여야 가능)
    CASE 
        WHEN L.loan_ext = 1 THEN '연장불가(횟수초과)'
        WHEN L.loan_due < CURDATE() THEN '연장불가(연체중)'
        ELSE '연장가능'
    END AS 연장상태,
    
    L.loan_ext -- (Hidden) 버튼 활성화/비활성화 로직용 True/False
    
FROM loans L
JOIN book_copies C ON L.cbk_id = C.cbk_id
JOIN books B ON C.bk_id = B.bk_id
WHERE 
    L.usr_id = 20233849            -- [변수] 학번
    AND L.loan_ret IS NULL  -- 현재 대출 중인 도서만
ORDER BY 
    L.loan_due ASC;         -- 반납 급한 순 정렬


-- -----------------------------------------------------
-- 3. [리스트] 예약 현황 조회 (취소 기능 포함)
-- -----------------------------------------------------
SELECT 
    R.resv_id,              -- (Hidden) 취소 처리용 ID
    
    -- 예약된 실물 도서 번호 (지정 예약인 경우 표시, 아니면 '-')
    IFNULL(R.cbk_id, '-') AS 예약도서번호,
    
    B.bk_title AS 서명,
    B.bk_id AS 청구기호,
    R.resv_date AS 예약일,
    R.resv_seq AS 대기순번,
    R.resv_stat AS 상태     -- '대기중', '수령가능'
    
FROM reservations R
JOIN books B ON R.bk_id = B.bk_id
WHERE 
    R.usr_id = 20233849            -- [변수] 학번
    AND R.resv_stat IN ('대기중', '수령가능') -- [ENUM 체크] 진행 중인 건만 조회
ORDER BY 
    R.resv_date DESC;


-- -----------------------------------------------------
-- 4. [기능] 대출 연장 (UPDATE)
-- -----------------------------------------------------
-- 조건: 본인 확인 + 연체 안 됨 + 연장 횟수 초과 안 함
UPDATE loans
SET 
    loan_due = DATE_ADD(loan_due, INTERVAL 7 DAY), -- 7일 연장
    loan_ext = TRUE                                -- 연장 횟수 차감(1회 한정이면 True로 변경)
WHERE 
    loan_id = 12345678             -- [변수] 대출 ID
    AND usr_id = 20233849          -- [변수] 학번 (본인확인)
    AND loan_due >= CURDATE() -- 연체된 책은 연장 불가
    AND loan_ext = FALSE;   -- 이미 연장한 책은 불가 (1회 제한 정책)


-- -----------------------------------------------------
-- 5. [기능] 예약 취소 (UPDATE)
-- -----------------------------------------------------
-- 조건: '대기중'이나 '수령가능' 상태일 때만 취소 가능
UPDATE reservations
SET 
    resv_stat = '취소됨'    -- [ENUM 체크] '취소' 아님 -> '취소됨'
WHERE 
    resv_id = 12345678             -- [변수] 예약 ID
    AND usr_id = 20233849          -- [변수] 학번
    AND resv_stat IN ('대기중', '수령가능');