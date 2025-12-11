USE library_system;
-- -----------------------------------------------------
-- 1. [상단 통계] 신청 상태별 건수 조회 (Dashboard)
-- -----------------------------------------------------
SELECT
    -- 1) 신규 신청 (PENDING -> 대기)
    (SELECT COUNT(*) FROM requests WHERE req_stat = '대기') AS 신규_신청,
    
    -- 2) 구매 진행중 (APPROVED -> 승인 or 구매완료)
    (SELECT COUNT(*) FROM requests WHERE req_stat IN ('승인', '구매완료')) AS 구매_진행중,
    
    -- 3) 반려 (REJECTED -> 반려)
    (SELECT COUNT(*) FROM requests WHERE req_stat = '반려') AS 반려_건수,
    
    -- 4) 전체 누적 신청
    (SELECT COUNT(*) FROM requests) AS 전체_누적_신청;


-- -----------------------------------------------------
-- 2. [리스트] 희망도서 신청 목록 조회 (검색/필터)
-- -----------------------------------------------------
SELECT
    T1.req_id       AS No,
    DATE_FORMAT(T1.req_date, '%Y-%m-%d') AS 신청일,
    
    -- 신청자 정보
    T2.usr_name     AS 신청자명,
    T2.usr_id       AS 학번,
    T2.usr_dept     AS 학과,
    
    -- 도서 정보
    T1.req_title    AS 서명,
    T1.req_auth     AS 저자,
    T1.req_pub      AS 출판사,
    T1.req_isbn     AS ISBN,
    
    -- 상태 및 관리 정보
    T1.req_stat     AS 상태,        -- (대기/승인/반려/구매완료)
    T1.req_memo     AS 신청사유,    -- (학생이 쓴 글)
    
    -- [수정됨] DDL 컬럼명 반영
    T1.req_proc_memo AS 반려사유    -- (관리자가 쓴 글 - 화면 표시용)
FROM
    requests T1
JOIN
    users T2 ON T1.usr_id = T2.usr_id
WHERE
    1=1
    -- [필터 1] 상태 필터 (전체/대기/승인/반려)
    AND T1.req_stat = '대기'  -- [변수] 선택된 값이 있을 때만 적용
    
    -- [필터 2] 통합 검색 (도서명, 저자, 학번)
    AND (
        T1.req_title LIKE CONCAT('%', '모던 자바스크립트 Deep Dive', '%') 
        OR T1.req_auth LIKE CONCAT('%', '이웅모', '%')
        OR T2.usr_id LIKE CONCAT('%', '20233849', '%')
    )
ORDER BY
    -- 대기중인 건을 최상단으로, 그 다음 최신순 정렬
    CASE WHEN T1.req_stat = '대기' THEN 1 ELSE 2 END ASC,
    T1.req_date DESC;


-- -----------------------------------------------------
-- 3. [액션] 관리자 승인/반려 처리 (UPDATE)
-- -----------------------------------------------------

-- [버튼: 승인] 검토 대기 -> 승인 (구매 절차 시작)
UPDATE requests
SET
    req_stat = '승인',
    req_proc_memo = NULL -- [수정됨] 반려 사유 초기화
WHERE
    req_id = 56; -- [변수] 신청 번호

-- [버튼: 반려] 검토 대기 -> 반려 (사유 입력 필수)
UPDATE requests
SET
    req_stat = '반려',
    req_proc_memo = '학습 무관 도서' -- [수정됨] 예: '학습 무관 도서', '예산 초과'
WHERE
    req_id = 55; -- [변수] 신청 번호

-- [버튼: 입고 완료/구매 완료] 승인 -> 구매완료 (최종 처리)
UPDATE requests
SET
    req_stat = '구매완료'
WHERE
    req_id = 54 AND req_stat = '승인';