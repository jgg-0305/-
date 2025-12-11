/*공지사항 ID로 상세 내용을 조회하고, 
해당 공지사항의 조회수(ntc_views)를 1 증가*/
USE library_system;
--  조회수 증가
UPDATE notices
SET ntc_views = ntc_views + 1 -- 조회수 1 증가
WHERE ntc_id = 1; -- 공지사항 ID

--  상세 내용 조회
SELECT
    n.ntc_title,
    n.ntc_content,
    n.ntc_file,
    DATE_FORMAT(n.ntc_date, '%Y.%m.%d %H:%i') AS '등록일시',
    n.ntc_views,
    l.lib_name AS '작성자'
FROM notices n
JOIN librarians l ON n.lib_id = l.lib_id
WHERE ntc_id = 1;