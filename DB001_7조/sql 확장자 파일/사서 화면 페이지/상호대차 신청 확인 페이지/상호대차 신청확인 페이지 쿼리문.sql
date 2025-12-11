USE library_system;
-- -----------------------------------------------------
-- 1. [상단 통계] 상태별 신청 건수 조회
-- -----------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM inter_library_loans WHERE ill_stat = '신청중')   AS 신규신청_건수,
    (SELECT COUNT(*) FROM inter_library_loans WHERE ill_stat = '배송중')   AS 배송중_건수,
    (SELECT COUNT(*) FROM inter_library_loans WHERE ill_stat = '도착')     AS 도착_수령대기_건수,
    -- 이번달 완료 건수 (반납완료 상태이면서, 신청일이 이번 달인 경우로 근사 계산)
    (SELECT COUNT(*) FROM inter_library_loans 
     WHERE ill_stat = '반납완료' 
       AND ill_req_date BETWEEN DATE_FORMAT(NOW(), '%Y-%m-01') AND LAST_DAY(NOW())
    ) AS 이번달_완료_건수;


-- -----------------------------------------------------
-- 2. [리스트] 상호대차 신청 목록 조회 (검색/필터)
-- -----------------------------------------------------
SELECT
    T1.ill_id       AS No,
    DATE_FORMAT(T1.ill_req_date, '%Y-%m-%d %H:%i') AS 신청일시,
    
    -- 신청자 정보
    T2.usr_name     AS 신청자명,
    T2.usr_id       AS 학번,
    T2.usr_dept     AS 학과,
    
    -- 도서 정보
    T1.ill_title    AS 서명,
    T1.ill_auth     AS 저자,
    T1.ill_lib_name AS 제공_도서관, -- [수정] 컬럼명 일치 (ill_target_lib -> ill_lib_name)
    
    -- 상태 및 관리 정보
    T1.ill_stat     AS 상태,        -- (신청중/배송중/도착/반납완료/취소됨)
    T1.ill_note     AS 신청자메모,   -- 학생이 쓴 비고
    T1.ill_ans_note AS 관리자메모    -- 사서가 쓴 비고/거절사유 [추가됨]
FROM
    inter_library_loans T1
JOIN
    users T2 ON T1.usr_id = T2.usr_id
WHERE
    1=1
    -- [필터 1] 상태 필터 (전체/신청중/배송중/...)
    AND T1.ill_stat = '신청중'  -- [변수] 선택된 값이 있을 때만 적용
    
    -- [필터 2] 통합 검색 (신청자명, 학번, 도서명)
    AND (
        T2.usr_name LIKE CONCAT('%', '조기강', '%') 
        OR T2.usr_id LIKE CONCAT('%', 20233849, '%')
        OR T1.ill_title LIKE CONCAT('%', '데이터 사이언스 입문', '%')
    )
ORDER BY
    -- '신청중'인 건을 최우선으로 보여주고, 그 외는 최신순
    CASE WHEN T1.ill_stat = '신청중' THEN 1 ELSE 2 END ASC,
    T1.ill_req_date DESC;


-- -----------------------------------------------------
-- 3. [액션] 상태 변경 워크플로우 (UPDATE)
-- -----------------------------------------------------

-- [버튼: 접수/발송] 신청중 -> 배송중
-- 학생의 신청을 확인하고 타 대학 도서관에 요청을 보냈을 때
UPDATE inter_library_loans
SET
    ill_stat = '배송중',
    ill_ans_note = NULL -- 기존 거절사유 등 초기화
WHERE
    ill_id = 1; -- [변수] 신청 번호

-- [버튼: 도착 확인] 배송중 -> 도착
-- 타 대학에서 책이 도착하여 학생에게 "수령하러 오세요" 알림을 보낼 때
UPDATE inter_library_loans
SET
    ill_stat = '도착'
WHERE
    ill_id = 1;

-- [버튼: 반납 처리] 도착 -> 반납완료
-- 학생이 책을 다 보고 반납하여, 타 대학으로 반송 처리했을 때
UPDATE inter_library_loans
SET
    ill_stat = '반납완료'
WHERE
    ill_id = 1;

-- [버튼: 거절] 신청중 -> 취소됨 (사유 입력 필수)
-- 우리 학교에 이미 있거나 대출 불가능한 경우
UPDATE inter_library_loans
SET
    ill_stat = '취소됨',
    ill_ans_note = '본교 소장 도서임' -- [변수] 거절 사유 (예: "본교 소장 도서임")
WHERE
    ill_id = 1;

