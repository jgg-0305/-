USE library_system;
-- -----------------------------------------------------
-- 1. [상단 통계] 대시보드 카운트
-- -----------------------------------------------------
-- 각 쿼리는 인덱스를 타므로 데이터가 많아도 0.1초 내에 실행됨
SELECT
    (SELECT COUNT(*) FROM users WHERE usr_stat != '졸업') AS 총_회원수,
    (SELECT COUNT(*) FROM users WHERE usr_lcnt > 0) AS 대출_중_회원,
    (SELECT COUNT(DISTINCT usr_id) FROM loans WHERE loan_ret IS NULL AND loan_due < CURDATE()) AS 연체_중_회원,
    (SELECT COUNT(*) FROM users WHERE usr_stat = '정지') AS 대출_정지_회원;


-- -----------------------------------------------------
-- 2. [리스트] 학생 목록 조회 (JOIN 최소화)
-- -----------------------------------------------------
SELECT
    T1.usr_id       AS 학번,
    T1.usr_name     AS 이름,
    T1.usr_dept     AS 학과,
    T1.usr_phone    AS 연락처, 
    T1.usr_lcnt     AS 대출권수, -- users 테이블 컬럼 바로 사용
    
    -- 연체 여부: 화면 표시용 (True/False)
    -- loans 테이블의 인덱스(usr_id, loan_ret)를 사용하여 매우 빠름
    (SELECT EXISTS(
        SELECT 1 FROM loans 
        WHERE usr_id = T1.usr_id AND loan_ret IS NULL AND loan_due < CURDATE()
    )) AS 연체_여부,
    
    T1.usr_stat     AS 상태, 
    
    -- 최근 방문일: 전체 조인 대신, 해당 유저의 최신 로그 1건만 조회 (Max)
    -- 인덱스(idx_entry_logs_user_date)가 있으면 순식간에 가져옴
    (SELECT DATE_FORMAT(MAX(log_time), '%Y-%m-%d')
     FROM entry_logs 
     WHERE usr_id = T1.usr_id) AS 최근_방문일
FROM
    users T1
WHERE
    1=1
    -- [검색 필터]
    AND (T1.usr_name LIKE CONCAT('%', '조기강', '%') OR T1.usr_id LIKE CONCAT('%', 20233849, '%'))
ORDER BY
    T1.usr_id ASC
LIMIT 10 OFFSET 0;


-- -----------------------------------------------------
-- 3. [상세] 학생 상세 정보 (모달)
-- -----------------------------------------------------
SELECT
    usr_id      AS 학번,
    usr_name    AS 이름,
    usr_dept    AS 학과,
    usr_phone   AS 연락처,
    usr_lcnt    AS 현재_대출권수,
    usr_gender  AS 성별,      
    usr_enrl    AS 재학여부, 
    usr_stat    AS 계정상태,
    
    -- 이메일 (가상 생성)
    CONCAT(usr_id, '@deu.ac.kr') AS 이메일,
    
    -- 최근 방문일 (상세)
    (SELECT DATE_FORMAT(MAX(log_time), '%Y-%m-%d %H:%i')
     FROM entry_logs WHERE usr_id = T1.usr_id) AS 최근_방문일,
    
    -- 누적 연체 횟수 (과거 기록 포함)
    (SELECT COUNT(*) FROM loans WHERE usr_id = T1.usr_id AND loan_ret > loan_due) AS 누적_연체,
    
    -- 현재 미반납 연체 권수
    (SELECT COUNT(*) FROM loans WHERE usr_id = T1.usr_id AND loan_ret IS NULL AND loan_due < CURDATE()) AS 미반납_연체
FROM
    users T1
WHERE
    usr_id = 20233849; -- [변수] 클릭한 학번


-- -----------------------------------------------------
-- 4. [상세] 탭1: 현재 대출 목록 조회
-- -----------------------------------------------------
SELECT 
    T2.cbk_id    AS 등록번호,
    T3.bk_title  AS 서명,
    T1.loan_date AS 대출일,
    T1.loan_due  AS 반납예정일,
    CASE 
        WHEN T1.loan_due < CURDATE() THEN '연체'
        ELSE '대출중'
    END AS 상태
FROM 
    loans T1
JOIN book_copies T2 ON T1.cbk_id = T2.cbk_id
JOIN books T3 ON T2.bk_id = T3.bk_id
WHERE 
    T1.usr_id = 20233849
    AND T1.loan_ret IS NULL
ORDER BY 
    T1.loan_due ASC;


-- -----------------------------------------------------
-- 5. [상세] 탭2: 패널티 이력 조회
-- -----------------------------------------------------
SELECT 
    pnl_type    AS 제재유형,
    pnl_reason  AS 상세사유,
    pnl_start   AS 시작일,
    pnl_end     AS 종료일,
    CASE 
        WHEN pnl_actv = 1 AND pnl_end >= CURDATE() THEN '적용중'
        ELSE '해제됨' 
    END AS 상태
FROM 
    penalties
WHERE 
    usr_id = 20233849
ORDER BY 
    pnl_start DESC;


-- -----------------------------------------------------
-- 6. [액션] 상태 변경 (정상/정지/졸업)
-- -----------------------------------------------------

-- [Case A] '정상' 또는 '졸업' 버튼 클릭 시
UPDATE users
SET usr_stat = '정상' -- [변수] '정상' or'정지'
WHERE usr_id = 20233849;

-- [Case B] '대출 정지' 버튼 클릭 시 (사유 및 기간 기록)
-- 1. 사용자 상태를 '정지'로 변경
UPDATE users
SET usr_stat = '정지'
WHERE usr_id = 20233849; -- [변수] 학번

-- 2. 패널티 테이블에 정지 기록 추가
INSERT INTO penalties (
    usr_id, 
    pnl_type, 
    pnl_reason, 
    pnl_start, 
    pnl_end,    
    pnl_actv
) VALUES (
    20233849,           -- [변수] 학번
    '직권정지',    -- 고정값
    '열람실 소란',           -- [변수] 입력받은 사유 (예: "열람실 소란")
    CURDATE(),   -- 시작일
    DATE_ADD(CURDATE(), INTERVAL 3 DAY), -- [변수] 입력받은 기간(일수)
    TRUE
);
