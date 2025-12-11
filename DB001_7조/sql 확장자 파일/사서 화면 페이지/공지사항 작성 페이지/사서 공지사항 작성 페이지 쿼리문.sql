USE library_system;
-- 작성자 정보 조회
SELECT
    lib_name
FROM
    librarians
WHERE
    lib_id = '로그인한_사서_ID';

-- 작성일 자동 채움을 위한 현재 시각 조회
SELECT
    NOW();
----------------------------------------------------------------------------
-- 공지사항 등록하기 버튼 클릭시 
-- 새로운 공지사항을 저장하기 위한 INSERT문 필요
----------------------------------------------------------------------------
INSERT INTO librarians (lib_id, lib_pw, lib_name, lib_role)
VALUES (
    'L1001',             
    'admin1234',        
    '관리자 김사서',     -- 이름
    '총무과'             -- 부서
) ON DUPLICATE KEY UPDATE lib_name = VALUES(lib_name);

INSERT INTO notices ( 
    lib_id, 
    ntc_title, 
    ntc_content, 
    ntc_date, 
    ntc_important, 
    ntc_views 
)  
VALUES ( 
    'L1001', -- ✅ 유효한 사서 ID 사용 (예: L1001)
    '입력된_공지_제목', 
    '입력된_공지_내용', 
    NOW(), 
    TRUE,    -- TRUE/FALSE 또는 1/0 사용
    0 
);




