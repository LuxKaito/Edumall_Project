use [DWH_Edumall]

-- Thêm ràng buộc PRIMARY KEY cho author_id trong bảng Author
ALTER TABLE Author
ADD CONSTRAINT PK_Author PRIMARY KEY (author_id);
GO

-- Thêm ràng buộc PRIMARY KEY cho topic_id trong bảng Topic
ALTER TABLE Topic
ADD CONSTRAINT PK_Topic PRIMARY KEY (topic_id);
GO

-- Thêm ràng buộc PRIMARY KEY cho course_id trong bảng Course
ALTER TABLE Course
ADD CONSTRAINT PK_Course PRIMARY KEY (course_id);
GO
-- Thêm ràng buộc FOREIGN KEY cho author_id và topic_id trong bảng Course
ALTER TABLE Course
ADD CONSTRAINT FK_Course_Author FOREIGN KEY (author_id) REFERENCES Author(author_id);
GO

ALTER TABLE Course
ADD CONSTRAINT FK_Course_Topic FOREIGN KEY (topic_id) REFERENCES Topic(topic_id);
GO

CREATE TABLE Last_updated (
    date_id INT IDENTITY(1,1) PRIMARY KEY,  -- Cột Date_id tự động tăng và là khóa chính
    full_date DATE,
    day INT,
    month INT,
    year INT
);
GO

INSERT INTO Last_updated (full_date, day, month, year)
SELECT full_date, 
       DAY(full_date) AS day, 
       MONTH(full_date) AS month, 
       YEAR(full_date) AS year
FROM Course;

WITH CTE AS (
    SELECT 
        [date_id], 
        [full_date], 
        [day], 
        [month], 
        [year],
        ROW_NUMBER() OVER (PARTITION BY [full_date] ORDER BY [Date_id]) AS rn
    FROM [DWH_Edumall].[dbo].[Last_updated]
)
DELETE FROM [DWH_Edumall].[dbo].[Last_updated]
WHERE [Date_id] IN (
    SELECT [date_id]
    FROM CTE
    WHERE rn > 1
);
GO

-- Thêm date_id vào bảng Course
ALTER TABLE Course
ADD date_id INT;
GO

-- Cập nhật bảng Course với các giá trị date_id từ bảng Last_updated
UPDATE Course
SET date_id = (SELECT date_id
               FROM Last_updated
               WHERE Last_updated.full_date = Course.full_date);
GO

-- Thêm ràng buộc khóa ngoại
ALTER TABLE Course
ADD CONSTRAINT FK_Course_LastUpdated
FOREIGN KEY (date_id) REFERENCES Last_updated (date_id);
GO

-- Xóa các cột full_date, day, month, year
ALTER TABLE Course
DROP COLUMN full_date, day, month, year;
GO

-- Tạo bảng Course_overview
CREATE TABLE Course_overview (
    course_overview_id INT IDENTITY(1,1) PRIMARY KEY,  -- Khóa chính
    coursename NVARCHAR(255),    -- Tên khóa học
    describe NVARCHAR(MAX),      -- Mô tả khóa học
    what_you_will_learn NVARCHAR(MAX) -- Những gì bạn sẽ học
);
GO

-- Chuyển dữ liệu từ bảng Course sang Course_overview
INSERT INTO Course_overview (coursename, describe, what_you_will_learn)
SELECT coursename, describe, what_you_will_learn
FROM Course;
GO

-- Thêm cột course_overview_id vào bảng Course
ALTER TABLE Course
ADD course_overview_id INT;
GO

-- Đồng bộ dữ liệu: Gán giá trị course_overview_id cho bảng Course
UPDATE Course
SET course_overview_id = co.course_overview_id
FROM Course_overview co
WHERE Course.coursename = co.coursename;
GO

-- Xóa các cột coursename, describe, what_you_will_learn khỏi bảng Course
ALTER TABLE Course
DROP COLUMN coursename, describe, what_you_will_learn;
GO

-- Đặt course_overview_id là NOT NULL
ALTER TABLE Course
ALTER COLUMN course_overview_id INT NOT NULL;
GO

-- Thêm khóa ngoại cho course_overview_id trong bảng Course
ALTER TABLE Course
ADD CONSTRAINT FK_Course_CourseOverview FOREIGN KEY (course_overview_id)
REFERENCES Course_overview (course_overview_id);
GO

-- Đổi tên bảng
EXEC sp_rename 'Author', 'DimAuthor';
EXEC sp_rename 'Course', 'FactCourse';
EXEC sp_rename 'Last_updated', 'DimLast_updated';
EXEC sp_rename 'Topic', 'DimTopic';
EXEC sp_rename 'Course_overview', 'DimCourse_overview';

-- Xử lý sau khi tạo cube
UPDATE DimCourse_overview
SET [describe] = LEFT([describe], 4000)
WHERE LEN([describe]) > 4000;

UPDATE DimCourse_overview
SET [what_you_will_learn] = LEFT([what_you_will_learn], 4000)
WHERE LEN([what_you_will_learn]) > 4000;


ALTER TABLE DimCourse_overview
ALTER COLUMN [describe] NVARCHAR(4000);

ALTER TABLE DimCourse_overview
ALTER COLUMN [what_you_will_learn] NVARCHAR(4000);









