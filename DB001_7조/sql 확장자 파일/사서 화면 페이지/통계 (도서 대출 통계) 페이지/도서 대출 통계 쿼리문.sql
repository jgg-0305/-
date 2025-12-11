USE library_system;
-- -----------------------------------------------------
-- 1. [메인 차트] 전체 도서 월별 대출 추이 (Line Chart)
-- -----------------------------------------------------
-- 화면 상단 '대출 현황' 그래프 및 '총 대출 뱃지' 데이터
SELECT
    stat_month      AS 월,
    SUM(loan_cnt)   AS 전체_대출_권수
FROM
    monthly_book_stats
WHERE
    stat_year = 2025  -- [변수] UI에서 선택한 연도
GROUP BY
    stat_month
ORDER BY
    stat_month ASC;


-- -----------------------------------------------------
-- 2. [서브 차트] 주제(장르)별 대출 비율 (Doughnut Chart)
-- -----------------------------------------------------
-- 화면 중단 좌측 '주제별 대출 비율' 그래프
SELECT
    G.gnr_name      AS 장르명,
    SUM(S.loan_cnt) AS 대출_권수,
    -- (옵션) 비율 계산은 보통 프론트엔드(Chart.js)에서 처리하지만, 필요시 SQL로 계산 가능
    ROUND(SUM(S.loan_cnt) * 100.0 / (SELECT SUM(loan_cnt) FROM monthly_book_stats WHERE stat_year = 2025), 1) AS 비율_퍼센트
FROM
    monthly_book_stats S
JOIN
    books B ON S.bk_id = B.bk_id
JOIN
    genres G ON B.gnr_id = G.gnr_id
WHERE
    S.stat_year = 2025 -- [변수] UI에서 선택한 연도
GROUP BY
    G.gnr_name
ORDER BY
    대출_권수 DESC;


-- -----------------------------------------------------
-- 3. [서브 차트] 대출 베스트 Top 5 (Bar Chart)
-- -----------------------------------------------------
-- 화면 중단 우측 '대출 베스트 Top 5' 그래프
SELECT
    B.bk_title      AS 서명,
    SUM(S.loan_cnt) AS 총_대출수
FROM
    monthly_book_stats S
JOIN
    books B ON S.bk_id = B.bk_id
WHERE
    S.stat_year = 2025 -- [변수] UI에서 선택한 연도
GROUP BY
    S.bk_id, B.bk_title
ORDER BY
    총_대출수 DESC
LIMIT 5;


-- -----------------------------------------------------
-- 4. [검색] 도서 기본 정보 및 총 누적 통계 조회
-- -----------------------------------------------------
-- 화면 하단 검색창 입력 후 '검색' 버튼 클릭 시 실행 (카드 좌측 정보)
SELECT
    B.bk_title      AS 서명,
    B.bk_auth       AS 저자,
    B.bk_pub        AS 출판사,
    -- [수정됨] 전체 누적이 아닌, '선택한 연도(2025)'의 대출 수만 합산
    (SELECT IFNULL(SUM(loan_cnt), 0) 
     FROM monthly_book_stats 
     WHERE bk_id = B.bk_id 
       AND stat_year = 2025  -- [변수] UI 선택 연도와 동일하게 필터링
    ) AS 선택연도_총_대출수
FROM
    books B
WHERE
    B.bk_title LIKE CONCAT('%', '검색어', '%') -- [변수] 예: '코스모스'
LIMIT 1;

-- -----------------------------------------------------
-- 5. [검색] 개별 도서 월별 대출 추이 (Mini Bar Chart)
-- -----------------------------------------------------
-- 화면 하단 검색 결과 카드 우측의 '미니 차트' 데이터
SELECT
    S.stat_month    AS 월,
    S.loan_cnt      AS 대출_횟수
FROM
    monthly_book_stats S
JOIN
    books B ON S.bk_id = B.bk_id
WHERE
    B.bk_title LIKE CONCAT('%', '검색어', '%') -- [변수] 위와 동일한 검색어
    AND S.stat_year = 2025                 -- [변수] 선택한 연도
ORDER BY
    S.stat_month ASC;

