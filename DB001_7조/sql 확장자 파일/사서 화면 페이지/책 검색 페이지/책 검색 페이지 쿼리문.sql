USE library_system;
-- -----------------------------------------------------
-- 1. 통합 도서 검색 조회 (복본 단위 조회)
-- -----------------------------------------------------
SELECT
    -- [도서 마스터 정보]
    T2.bk_id        AS 청구기호_ID, -- 그룹핑 기준 키
    T2.bk_title     AS 서명,
    T2.bk_auth      AS 저자,
    T2.bk_pub       AS 출판사,
    T2.bk_year      AS 발행연도,
    T2.bk_isbn      AS ISBN,
    T2.bk_image     AS 표지이미지, -- [화면 표시용]
    
    -- [도서 상태 뱃지용 집계 (서브쿼리)]
    (SELECT COUNT(*) FROM book_copies WHERE bk_id = T2.bk_id) AS 총_소장권수,
    (SELECT COUNT(*) FROM book_copies WHERE bk_id = T2.bk_id AND cbk_stat = '대출가능') AS 대출가능권수,

    -- [복본 상세 정보]
    T1.cbk_id       AS 등록번호,
    CONCAT(T2.bk_id, ' c.', T1.cbk_vol) AS 청구기호_조합, -- 예: 005.74 김진데 c.1
    T1.cbk_vol      AS 복본번호,
    T3.loc_name     AS 소장위치,
    T1.cbk_stat     AS 도서상태, -- (대출가능, 대출중, 분실, 파손)
    
    -- [대출 정보 (현재 대출중인 경우만)]
    T5.usr_name     AS 대출자_이름,
    T5.usr_id       AS 대출자_학번,
    DATE_FORMAT(T4.loan_due, '%Y-%m-%d') AS 반납예정일,
    
    -- [예약 정보 (1순위 예약자 표시)]
    (SELECT CONCAT(U.usr_name, ' (', U.usr_id, ')')
     FROM reservations R
     JOIN users U ON R.usr_id = U.usr_id
     WHERE R.cbk_id = T1.cbk_id 
       AND R.resv_stat = '대기중'
     ORDER BY R.resv_seq ASC 
     LIMIT 1
    ) AS 예약자_정보

FROM
    book_copies T1
JOIN
    books T2 ON T1.bk_id = T2.bk_id
LEFT JOIN
    locations T3 ON T1.loc_id = T3.loc_id
LEFT JOIN
    loans T4 ON T1.cbk_id = T4.cbk_id AND T4.loan_ret IS NULL -- 현재 대출중인 건 조인
LEFT JOIN
    users T5 ON T4.usr_id = T5.usr_id
WHERE
    1=1
    /* [검색 조건: UI Select Box에 따라 동적 적용] */
    -- [전체 검색인 경우]
    AND (
        T2.bk_title LIKE CONCAT('%', '데이터 사이언스 입문', '%')        -- 서명
        OR T2.bk_auth LIKE CONCAT('%', '김진, 최정아', '%')      -- 저자
        OR T1.cbk_id LIKE CONCAT('%', '9791196752521', '%')       -- 등록번호
        OR T5.usr_name LIKE CONCAT('%', '박지민', '%')     -- 대출자명
    )
    
    /* [개별 필터링 예시]
    -- AND T2.bk_title LIKE ... 
    -- AND T1.cbk_id = ...
    */
ORDER BY
    T2.bk_title ASC,  -- 서명순 정렬
    T1.cbk_vol ASC    -- 복본번호순 정렬 (c.1, c.2 ...)
LIMIT 50;


