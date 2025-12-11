USE library_system;

-- -----------------------------------------------------
-- 0. [사전 작업] 필수 인덱스 생성
-- -----------------------------------------------------
-- 대출 이력 조회 시 '특정 사용자'의 기록을 '날짜 역순'으로 빠르게 가져오기 위함
CREATE INDEX idx_loans_usr_date 
ON loans (usr_id, loan_date);


-- -----------------------------------------------------
-- 1. [헤더] 사용자 기본 정보 조회
-- -----------------------------------------------------
-- 화면 상단: "20233849 ( 컴퓨터공학과, 정상 )" 표시용
SELECT
    usr_name  AS 이름,
    usr_dept  AS 학과,  
    usr_stat  AS 상태    
FROM
    users
WHERE
    usr_id = '20233849'; -- [변수] 로그인한 사용자 ID


-- -----------------------------------------------------
-- 2. [리스트] 대출 History 목록 조회
-- -----------------------------------------------------
-- 조건: 로그인한 사용자의 '반납이 완료된(loan_ret IS NOT NULL)' 기록만 조회
SELECT
    T1.loan_id      AS No,
    T2.cbk_id       AS 등록번호,
    T3.bk_title     AS 서명,
    T3.bk_auth      AS 저자,
    DATE_FORMAT(T1.loan_date, '%Y-%m-%d') AS 대출일,
    DATE_FORMAT(T1.loan_due,  '%Y-%m-%d') AS 반납예정일,
    DATE_FORMAT(T1.loan_ret,  '%Y-%m-%d') AS 반납일,

    -- [상태 계산] 반납일이 예정일보다 늦으면 '연체반납', 아니면 '반납완료'
    CASE
        WHEN T1.loan_ret > T1.loan_due THEN '연체반납'
        ELSE '반납완료'
    END AS 상태
FROM
    loans T1
    JOIN book_copies T2 ON T1.cbk_id = T2.cbk_id
    JOIN books          T3 ON T2.bk_id  = T3.bk_id
WHERE
    T1.usr_id = '20233849'  -- [필수] 사용자 ID
    AND T1.loan_date BETWEEN '2025-01-01 00:00:00' AND '2025-12-06 23:59:59' -- [필터] 조회 기간
    AND T1.loan_ret IS NOT NULL -- [필터] 반납 완료된 건만 (History)
ORDER BY
    T1.loan_date DESC; -- [정렬] 최신순