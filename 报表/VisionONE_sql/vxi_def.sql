USE [master]
GO
/****** Object:  Database [vxi_def]    Script Date: 2016/12/8 13:07:46 ******/
CREATE DATABASE [vxi_def]

GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [vxi_def].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [vxi_def] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [vxi_def] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [vxi_def] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [vxi_def] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [vxi_def] SET ARITHABORT OFF 
GO
ALTER DATABASE [vxi_def] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [vxi_def] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [vxi_def] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [vxi_def] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [vxi_def] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [vxi_def] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [vxi_def] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [vxi_def] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [vxi_def] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [vxi_def] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [vxi_def] SET  DISABLE_BROKER 
GO
ALTER DATABASE [vxi_def] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [vxi_def] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [vxi_def] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [vxi_def] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [vxi_def] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [vxi_def] SET READ_COMMITTED_SNAPSHOT OFF 
GO

ALTER DATABASE [vxi_def] SET RECOVERY FULL 
GO
ALTER DATABASE [vxi_def] SET  MULTI_USER 
GO
ALTER DATABASE [vxi_def] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [vxi_def] SET DB_CHAINING OFF 

GO
USE [vxi_def]
GO
/****** Object:  DatabaseRole [test]    Script Date: 2016/12/8 13:07:47 ******/
CREATE ROLE [test]
GO
/****** Object:  StoredProcedure [dbo].[get_xml]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[get_xml]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	select * from action
END


GO
/****** Object:  StoredProcedure [dbo].[sp_action_setup]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_action_setup]  AS
delete from [ACTION]

if exists(select * from syscolumns where id = object_id('ACTION') and (not (autoval is null)))
	SET IDENTITY_INSERT ACTION ON


if exists(select * from syscolumns where id = object_id('ACTION') and (not (autoval is null)))
	SET IDENTITY_INSERT ACTION OFF



GO
/****** Object:  StoredProcedure [dbo].[sp_add_favorite]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_add_favorite]
	-- Add the parameters for the stored procedure here
	@userid varchar(20), 
	@title varchar(100),
	@url varchar(500),
	@Action varchar(50)
    ,@Method varchar(50)
    ,@FlowID int
    ,@ModId varchar(50)
    ,@NodeId int
    ,@Params varchar(2000)
    ,@SortId int




           

AS
BEGIN
declare @count int
select @count = isnull(max(Favorid), 0) + 1 from [Favorite]
print @count
INSERT INTO [Favorite]
           ([FavorId]
		   ,[UserId]
           ,[Title]
           ,[URL]
           ,[AddTime]
           ,[VisitTime]
           ,[SortId]
           ,[ModId]
           ,[Method]
           ,[FlowID]
           ,[NodeId]
           ,[Action]
           ,[Params]
           ,[Note]
           ,[Enabled])
     VALUES
           ( 
			@count
		   ,@userid
           ,@title
           ,@url
           ,getdate()
           ,getdate()
		   ,@SortId
           ,@ModId
           ,@Method
           ,@FlowID
           ,@NodeId
           ,@Action
           ,@Params	
           ,''
           ,1)
	select * from Favorite where userid=@userid and Enabled = 1
END

GO
/****** Object:  StoredProcedure [dbo].[sp_calendar_setup]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_calendar_setup]
	@year int = 0
AS
	declare @month int
	if isnull(@year, 0) = 0 begin
		select @year = year(getdate()), @month = month(getdate())
		if @month = 12 begin
			select @year = @year + 1
		end
	end
	declare @loop int, @nextyear int
	select @loop = @year * 10000 + 101, @nextyear = (@year + 1) * 10000 + 101
	while @loop < @nextyear begin
		if @loop % 100 = 1 begin
			if not exists (select * from monthly where CalDate = @loop - 1) begin
				insert into monthly (caldate) values (@loop - 1)
			end
		end
		if not exists (select * from calendar where caldate = @loop) begin
			insert into calendar (caldate) values (@loop)
		end
		set @loop = dbo.func_tomorrow(str(@loop))
	end


GO
/****** Object:  StoredProcedure [dbo].[sp_callback]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =====================================================================
-- Author: wei.jia@vxichina.com
-- Create date: Dec 7, 2007
-- Description:	Get and execute the callback codes defined in [Callback]
-- =====================================================================

CREATE PROCEDURE [dbo].[sp_callback]
	@objname varchar(50),
	@eventname	varchar(50),
	@xtype int = 0,				-- internal use.
	@param xml,					-- input parameter
	@param2 xml output			-- output parameter
AS
begin
	
	declare @sqltext nvarchar(4000)
	declare @seq int, @on_succ varchar(20), @on_fail varchar(20)
	
	print 'Objname: ' + @objname + char(9) + char(9) + 'Eventname: ' + @eventname
	print '----------------------------------------------------------------------'
	
	set @seq = 0
	select top 1 @sqltext = SqlText, @seq = [Sequence], @on_succ = OnSuccess, @on_fail = Onfailure from callback 
		where ObjName = @objname and EventName = @eventname and xtype = @xtype and Enabled = 1 and [Sequence] > @seq 
		order by [Sequence] 
	
	while @@rowcount != 0 begin
		begin try
			-- Clear Error Info.
			set @param2 = dbo.func_paramobj_set(@param2, 'error', '0')
			set @param2 = dbo.func_paramobj_set(@param2, 'errormsg', '')
			exec sp_executesql @sqltext, N'@param xml, @param2 xml output', @param, @param2 output
		end try
		begin catch
			-- Set Error Info.
			set @param2 = dbo.func_paramobj_set(@param2, 'error', error_number())
			set @param2 = dbo.func_paramobj_set(@param2, 'errormsg', error_message())
		end catch

		if (dbo.func_paramobj_get(@param2, 'error')) != 0 begin
			print char(9) + 'Step = ' + cast(@seq as varchar(10)) + char(9) + char(9) 
				+ 'error = ' + dbo.func_paramobj_get(@param2, 'error') + char(9) + char(9) 
				+ 'errormsg = ' + dbo.func_paramobj_get(@param2, 'errormsg') 
		
			if @on_fail = 'Exit' begin
				set @param2 = dbo.func_paramobj_set(@param2, 'ret_type', 'EXIT')
				goto _ENDCALL
			end
			if @on_fail = 'Abort' begin 
				set @param2 = dbo.func_paramobj_set(@param2, 'ret_type', 'ABORT')
				goto _ENDCALL
			end
		end
		select top 1 @sqltext = SqlText, @seq = [Sequence], @on_succ = OnSuccess, @on_fail = Onfailure from callback 
			where ObjName = @objname and EventName = @eventname and xtype = @xtype and Enabled = 1 and [Sequence] > @seq 
			order by [Sequence] 
	end;
	
	if dbo.func_paramobj_get(@param2, 'ret_type') is null set @param2 = dbo.func_paramobj_set(@param2, 'ret_type', 'SUCCESS')
	
_ENDCALL:

	print char(9) + 'ret_type = ' + dbo.func_paramobj_get(@param2, 'ret_type') 
	print null
	print null

end

GO
/****** Object:  StoredProcedure [dbo].[sp_country_setup]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Chanqing
-- Create date: 2007.07.29
-- Description:	国家记录初始化
-- =============================================
CREATE PROCEDURE [dbo].[sp_country_setup]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;

	delete country

	insert into country (Country, name_chn, name_eng, enabled) values ('93', '阿富汗', 'Afghanistan', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('213', '阿尔及利亚', 'Algeria', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('376', '安道尔', 'Andorra', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1264', '安圭拉', 'Anguilla', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1268', '安提瓜和巴布达', 'Antigua and Barbuda', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('374', '亚美尼亚', 'Armenia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('61', '澳大利亚', 'Australia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('994', '阿塞拜疆', 'Azerbaijan', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('880', '孟加拉国', 'Bangladesh', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('375', '白俄罗斯', 'Belarus', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('501', '伯利兹', 'Belize', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1441', '百慕大', 'Bermuda', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('591', '玻利维亚', 'Bolivia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('267', '博茨瓦纳', 'Botswana', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('55', '巴西', 'Brazil', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1284', '英属维尔京群岛', 'British Virgin Islands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('359', '保加利亚', 'Bulgaria', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('95', '缅甸', 'Burma', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('855', '柬埔寨', 'Cambodia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1', '加拿大', 'Canada', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1345', '开曼群岛', 'Cayman Islands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('235', '乍得', 'Chad', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('86', '中国', 'China', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('61', '科科斯（基林）群岛', 'Cocos (Keeling) Islands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('269', '科摩罗', 'Comoros', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('242', '刚果（布）', 'Congo, Republic of the', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('506', '哥斯达黎加', 'Costa Rica', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('385', '克罗地亚', 'Croatia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('357', '塞浦路斯', 'Cyprus', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('45', '丹麦', 'Denmark', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1767', '多米尼克', 'Dominica', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('593', '厄瓜多尔', 'Ecuador', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('503', '萨尔瓦多', 'El Salvador', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('291', '厄立特里亚', 'Eritrea', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('251', '埃塞俄比亚', 'Ethiopia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('500', '福克兰群岛（马尔维纳斯）', 'Falkland Islands (Islas Malvinas)', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('679', '斐济', 'Fiji', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('33', '法国', 'France', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('689', '法属波利尼西亚', 'French Polynesia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('241', '加蓬', 'Gabon', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('49', '德国', 'Germany', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('350', '直布罗陀', 'Gibraltar', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('299', '格陵兰', 'Greenland', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('590', '瓜德罗普', 'Guadeloupe', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('502', '危地马拉', 'Guatemala', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('224', '几内亚', 'Guinea', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('592', '圭亚那', 'Guyana', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('504', '洪都拉斯', 'Honduras', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('36', '匈牙利', 'Hungary', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('91', '印度', 'India', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('98', '伊朗', 'Iran', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('353', '爱尔兰', 'Ireland', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('39', '意大利', 'Italy', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('81', '日本', 'Japan', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('962', '约旦', 'Jordan', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('254', '肯尼亚', 'Kenya', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('850', '朝鲜', 'Korea, North', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('965', '科威特', 'Kuwait', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('856', '老挝', 'Laos', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('961', '黎巴嫩', 'Lebanon', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('231', '利比里亚', 'Liberia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('423', '列支敦士登', 'Liechtenstein', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('352', '卢森堡', 'Luxembourg', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('389', '前南马其顿', 'Macedonia, The Former Yugoslav Republic of', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('265', '马拉维', 'Malawi', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('960', '马尔代夫', 'Maldives', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('356', '马耳他', 'Malta', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('692', '马绍尔群岛', 'Marshall Islands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('222', '毛里塔尼亚', 'Mauritania', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('269', '马约特', 'Mayotte', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('691', '密克罗尼西亚', 'Micronesia, Federated States of', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('377', '摩纳哥', 'Monaco', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1664', '蒙特塞拉特', 'Montserrat', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('258', '莫桑比克', 'Mozambique', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('674', '瑙鲁', 'Nauru', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('31', '荷兰', 'Netherlands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('687', '新喀里多尼亚', 'New Caledonia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('505', '尼加拉瓜', 'Nicaragua', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('234', '尼日利亚', 'Nigeria', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('6723', '诺福克岛', 'Norfolk Island', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('47', '挪威', 'Norway', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('92', '巴基斯坦', 'Pakistan', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('507', '巴拿马', 'Panama', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('595', '巴拉圭', 'Paraguay', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('63', '菲律宾', 'Philippines', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('48', '波兰', 'Poland', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('974', '卡塔尔', 'Qatar', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('40', '罗马尼亚', 'Romania', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('250', '卢旺达', 'Rwanda', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1869', '圣基茨和尼维斯', 'Saint Kitts and Nevis', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('508', '圣皮埃尔和密克隆', 'Saint Pierre and Miquelon', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('685', '萨摩亚', 'Samoa', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('239', '圣多美和普林西比', 'Sao Tome and Principe', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('221', '塞内加尔', 'Senegal', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('248', '塞舌尔', 'Seychelles', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('65', '新加坡', 'Singapore', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('386', '斯洛文尼亚', 'Slovenia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('252', '索马里', 'Somalia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('', '南乔治亚岛和南桑德韦奇岛', 'South Georgia and the South Sandwich Islands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('94', '斯里兰卡', 'Sri Lanka', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('597', '苏里南', 'Suriname', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('268', '斯威士兰', 'Swaziland', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('41', '瑞士', 'Switzerland', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('886', '台湾', 'Taiwan', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('255', '坦桑尼亚', 'Tanzania', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1242', '巴哈马', 'The Bahamas', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('228', '多哥', 'Togo', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('676', '汤加', 'Tonga', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('216', '突尼斯', 'Tunisia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('993', '土库曼斯坦', 'Turkmenistan', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('688', '图瓦卢', 'Tuvalu', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('380', '乌克兰', 'Ukraine', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('44', '英国', 'United Kingdom', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('598', '乌拉圭', 'Uruguay', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('678', '瓦努阿图', 'Vanuatu', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('84', '越南', 'Vietnam', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('681', '瓦利斯和富图纳', 'Wallis and Futuna', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('967', '也门', 'Yemen', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('260', '赞比亚', 'Zambia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('355', '阿尔巴尼亚', 'Albania', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('684', '美属萨摩亚', 'American Samoa', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('244', '安哥拉', 'Angola', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('672', '南极洲', 'Antarctica', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('54', '阿根廷', 'Argentina', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('297', '阿鲁巴', 'Aruba', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('43', '奥地利', 'Austria', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('973', '巴林', 'Bahrain', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1246', '巴巴多斯', 'Barbados', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('32', '比利时', 'Belgium', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('229', '贝宁', 'Benin', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('975', '不丹', 'Bhutan', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('387', '波黑', 'Bosnia and Herzegovina', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('673', '文莱', 'Brunei Darussalam', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('226', '布基纳法索', 'Burkina Faso', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('257', '布隆迪', 'Burundi', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('237', '喀麦隆', 'Cameroon', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('238', '佛得角', 'Cape Verde', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('236', '中非', 'Central African Republic', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('56', '智利', 'Chile', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('61', '圣诞岛', 'Christmas Island', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('57', '哥伦比亚', 'Colombia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('243', '刚果（金）', 'Congo, Democratic Republic of the', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('682', '库克群岛', 'Cook Islands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('225', '科特迪瓦', 'Cote d''Ivoire', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('53', '古巴', 'Cuba', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('420', '捷克', 'Czech Republic', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('253', '吉布提', 'Djibouti', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1809', '多米尼加', 'Dominican Republic', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('20', '埃及', 'Egypt', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('240', '赤道几内亚', 'Equatorial Guinea', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('372', '爱沙尼亚', 'Estonia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('298', '法罗群岛', 'Faroe Islands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('358', '芬兰', 'Finland', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('594', '法属圭亚那', 'French Guiana', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('995', '格鲁吉亚', 'Georgia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('233', '加纳', 'Ghana', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('30', '希腊', 'Greece', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1473', '格林纳达', 'Grenada', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1671', '关岛', 'Guam', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1481', '根西岛', 'Guernsey', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('245', '几内亚比绍', 'Guinea-Bissau', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('509', '海地', 'Haiti', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('379', '梵蒂冈', 'Holy See (Vatican City)', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('852', '香港', 'Hong Kong (SAR)', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('354', '冰岛', 'Iceland', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('62', '印度尼西亚', 'Indonesia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('964', '伊拉克', 'Iraq', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('972', '以色列', 'Israel', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1876', '牙买加', 'Jamaica', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('73', '哈萨克斯坦', 'Kazakhstan', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('686', '基里巴斯', 'Kiribati', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('82', '韩国', 'Korea, South', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('996', '吉尔吉斯斯坦', 'Kyrgyzstan', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('371', '拉脱维亚', 'Latvia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('266', '莱索托', 'Lesotho', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('218', '利比亚', 'Libya', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('370', '立陶宛', 'Lithuania', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('853', '澳门', 'Macao', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('261', '马达加斯加', 'Madagascar', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('60', '马来西亚', 'Malaysia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('223', '马里', 'Mali', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('596', '马提尼克', 'Martinique', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('230', '毛里求斯', 'Mauritius', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('52', '墨西哥', 'Mexico', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('373', '摩尔多瓦', 'Moldova', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('976', '蒙古', 'Mongolia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('212', '摩洛哥', 'Morocco', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('264', '纳米尼亚', 'Namibia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('977', '尼泊尔', 'Nepal', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('599', '荷属安的列斯', 'Netherlands Antilles', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('64', '新西兰', 'New Zealand', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('227', '尼日尔', 'Niger', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('683', '纽埃', 'Niue', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1', '北马里亚纳', 'Northern Mariana Islands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('968', '阿曼', 'Oman', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('680', '帕劳', 'Palau', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('675', '巴布亚新几内亚', 'Papua New Guinea', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('51', '秘鲁', 'Peru', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('351', '葡萄牙', 'Portugal', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1809', '波多黎各', 'Puerto Rico', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('262', '留尼汪', 'Reunion', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('7', '俄罗斯', 'Russia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('290', '圣赫勒拿', 'Saint Helena', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1758', '圣卢西亚', 'Saint Lucia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1784', '圣文森特和格林纳丁斯', 'Saint Vincent and the Grenadines', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('378', '圣马力诺', 'San Marino', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('966', '沙特阿拉伯', 'Saudi Arabia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('381', '塞尔维亚和黑山', 'Serbia and Montenegro', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('232', '塞拉利', 'Sierra Leone', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('421', '斯洛伐克', 'Slovakia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('677', '所罗门群岛', 'Solomon Islands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('27', '南非', 'South Africa', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('34', '西班牙', 'Spain', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('249', '苏丹', 'Sudan', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('47', '斯瓦尔巴岛和扬马延岛', 'Svalbard', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('46', '瑞典', 'Sweden', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('963', '叙利亚', 'Syria', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('992', '塔吉克斯坦', 'Tajikistan', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('66', '泰国', 'Thailand', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('220', '冈比亚', 'The Gambia', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('690', '托克劳', 'Tokelau', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1868', '特立尼达和多巴哥', 'Trinidad and Tobago', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('90', '土耳其', 'Turkey', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1649', '特克斯和凯科斯群岛', 'Turks and Caicos Islands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('256', '乌干达', 'Uganda', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('971', '阿拉伯联合酋长国', 'United Arab Emirates', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1', '美国', 'United States', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('998', '乌兹别克斯坦', 'Uzbekistan', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('58', '委内瑞拉', 'Venezuela', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('1340', '美属维尔京群岛', 'Virgin Islands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('263', '津巴布韦', 'Zimbabwe', 1)
	/*
	insert into country (Country, name_chn, name_eng, enabled) values ('', '赫德岛和麦克唐纳岛', 'Heard Island and McDonald Islands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('', '布维岛', 'Bouvet Island', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('', '英属印度洋领地', 'British Indian Ocean Territory', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('', '欧盟', 'European Union', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('', '法属南部领土', 'French Southern and Antarctic Lands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('', '泽西岛', 'Jersey', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('', '马恩岛', 'Man, Isle of', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('', '皮特凯恩', 'Pitcairn Islands', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('', '西撒哈拉', 'Western Sahara', 1)
	insert into country (Country, name_chn, name_eng, enabled) values ('', '南斯拉夫', 'Yugoslavia', 1)
	*/

	update country
		set countryname = name_chn

	delete country where country = 0
END

GO
/****** Object:  StoredProcedure [dbo].[sp_database_link_init]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===============================================================================================================
-- Author:		WuYiBin
-- Create date: 2008.12.4
-- Description:	数据库连接的建立
-- Example: sp_database_link_init @host='192.168.0.100',@LinkName='test1_link',@loguser='aa',@logpass='aa',@dbtype=1
-- ===============================================================================================================
CREATE PROCEDURE [dbo].[sp_database_link_init]
	@Host		varchar(20),				-- 主机ip地址或主机名
	@LinkName	varchar(20) = 'link_cms',	-- 数据库链接名
	@LogUser	varchar(20) = '',			-- 登陆用户名
	@LogPass    varchar(20) = '',			-- 登陆密码
	@DbType     tinyint = 1					-- 数据库类型
											--[SqlServer:1;	Oracle:2]
AS
begin try
	declare @ExSql varchar(4000), @Error int
	set @Error = 0
	
	IF exists(SELECT srv.name FROM sys.servers srv WHERE srv.server_id != 0 AND srv.name = @LinkName) 
		EXEC master.dbo.sp_dropserver @server=@LinkName, @droplogins='droplogins'

	set @ExSql = case @DbType
						when 1 then 'exec sp_addlinkedserver '''+ @LinkName 
							+ ''','''',''SQLOLEDB'','''+@Host+''''
						when 2 then 'exec sp_addlinkedserver '''+ @LinkName 
							+ ''',''Oracle'',''MSDAORA'','''+@Host+''''
					end
	print @ExSql
	exec(@ExSql)

	set @ExSql = case @DbType
						when 1 then 'exec sp_addlinkedsrvlogin '''+ @LinkName 
							+''',''false'',null,'''+@LogUser+''','''+@LogPass+''''
						when 2 then 'exec sp_addlinkedsrvlogin '''+ @LinkName 
							+''',false,''sa'','''+@LogUser+''','''+@LogPass+''''
					end
	print @ExSql
	exec(@ExSql)

	select @LinkName DbLink
	return @Error

end try
begin catch
	set @Error = -1
	print '[sp_database_link_init](数据库链接创建失败！)'
	return @Error
end catch

GO
/****** Object:  StoredProcedure [dbo].[sp_date_range]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_date_range]
	@recdate int = 0,	-- 格式：yyyymmdd，0：表示当月，dd=00：表示月报，mm=00：表示年报
	@date_beg int = null output,
	@date_end int = null output
AS
	declare @year int, @month int, @day int, @dayend varchar(20)

	if isnull(@recdate, 0) < 19800100 begin
		declare @date datetime
		select @date = datediff(mm, -1, getdate())
		select @year = year(@date), @month = month(@date), @day = 0
		select @recdate = @year * 10000 + @month + 100
	end
	else begin
		select @year = @recdate / 10000, @month = @recdate / 100 % 100, @day = @recdate % 100
	end

	if @day != 0 begin
		-- date range is a day
		select @date_beg = @recdate, @date_end = @recdate
	end
	else if @month != 0 begin
		-- date range is a month
		set @date_beg = @recdate + 1
		set @date_end = dbo.func_month_last(str(@date_beg))
	end
	else begin
		-- date range is a year
		select @date_beg = @recdate + 101, @date_end = @recdate + 1231
	end


GO
/****** Object:  StoredProcedure [dbo].[sp_dblog_clear]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================================
-- Author:		WuYiBin
-- Create date: 2010.12.27
-- Description:	数据库日志清除操作(支持SQLServer2005/2008)
-- Example: sp_dblog_clear @DBList = 'vxi_ucd,vxi_rtd,wfm_biz,vxi_def,wfm_def'
-- ===========================================================================
CREATE PROCEDURE [dbo].[sp_dblog_clear]
	@DBList	varchar(200)	= ''	-- dbname list
AS
begin try
	declare	@Len			int,
			@pos			int,
			@DBName			varchar(30),
			@Error			int
	declare @T_DBList table(RowNum int IDENTITY(1,1) NOT NULL, 
							DBName varchar(30))
	set @Error = 0
	
	set @Len = len(@DBList)

	while @len > 0 begin
		set @pos = charindex(',', @DBList)
		if @pos > 1 begin
			set @DBName = substring(@DBList, 1, @pos - 1)
			set @DBList = substring(@DBList, @pos + 1, @len)
			set @len = len(@DBList)
			insert into @T_DBList(DBName) values(@DBName)
		end
		else begin
			set @DBName = @DBList
			insert into @T_DBList(DBName) values(@DBName)
			set @len = 0
		end
	end

	declare @RowNum			int,
			@LoopCounter	int,
			@DBVersion		varchar(4),
			@Database_Id	tinyint,
			@Recovery_Model	varchar(12),	--[1-FULL;2-BULK_LOGGED;3-SIMPLE]
			@LogName		varchar(30),
			@sql			varchar(2000)
			
	set @LoopCounter = 1

	select @RowNum = count(*) from @T_DBList
	
	select @DBVersion = right(substring(@@version, 1, 25), 4)

	while @RowNum > 0 and @Error = 0 begin
		select @DBName = DBName
			from @T_DBList
			where RowNum = @LoopCounter
		if exists(select 1 from sys.databases where name = @DBName) begin
			if @DBVersion = '2008' begin
				select @Database_Id = database_id,
						@Recovery_Model = recovery_model_desc
					from sys.databases
					where name = @DBName
				select @LogName = name
						from sys.master_files
						where database_id = @Database_Id
							and type = 1
					
				set @sql = 'USE MASTER;'
					
				if @Recovery_Model != 'SIMPLE' begin
					select @sql = @sql + 'ALTER DATABASE ' + @DBName + ' SET RECOVERY SIMPLE WITH NO_WAIT;'
					select @sql = @sql + 'ALTER DATABASE ' + @DBName + ' SET RECOVERY SIMPLE;'
					select @sql = @sql + 'USE ' + @DBName + ';'
					select @sql = @sql + 'DBCC SHRINKFILE (' + @LogName + ', TRUNCATEONLY);'
					select @sql = @sql + 'ALTER DATABASE ' + @DBName + ' SET RECOVERY ' + @Recovery_Model + ' WITH NO_WAIT;'
					select @sql = @sql + 'ALTER DATABASE ' + @DBName + ' SET RECOVERY ' + @Recovery_Model + ';'
					--print @sql
					exec (@sql)
				end
				else begin
					select @sql = 'USE ' + @DBName + ';'
					select @sql = @sql + 'DBCC SHRINKFILE (' + @LogName + ', TRUNCATEONLY);'
					--print @sql
					exec (@sql)
				end
			end
			else begin
				execute('dump transaction ' + @DBName + ' with no_log');
				set @Error = @@Error

				if @Error = 0 begin
					execute('backup log ' + @DBName + ' with no_log');
					set @Error = @@Error
				end
			
				if @Error = 0 begin
					execute('dbcc shrinkdatabase(' + @DBName + ')');
					set @Error = @@Error
				end
			end

			if @Error = 0 begin
				print @DBName + ' Clear Over!'
			end
		end

		select @RowNum = @RowNum - 1, 
				@LoopCounter = @LoopCounter + 1
	end
	
	return @Error

end try
begin catch
	set @Error = -1
	print Error_Message()
	print '[sp_dblog_clear](数据库日志清除失败！)'
	return @Error
end catch
GO
/****** Object:  StoredProcedure [dbo].[sp_dict_privflag_setup]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_dict_privflag_setup]
AS
update dictionary set privflag = (privflag | 0x01) where dicname = 'prjid'
update dictionary set privflag = (privflag | 0x02) where sortfield = 'skill'
update dictionary set privflag = (privflag | 0x04) where sortfield = 'agent'
update dictionary set privflag = (privflag | 0x10) where sortfield = 'prjid'
update dictionary set privflag = (privflag | 0x20) where sortfield = 'skill'
update dictionary set privflag = (privflag | 0x40) where sortfield = 'agent'

GO
/****** Object:  StoredProcedure [dbo].[sp_dict_setup]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_dict_setup]
AS
-----------------------------DICTIONARY----------------------------------------------------
if exists(select * from syscolumns where id = object_id('WFM_DEF..DICTIONARY') and (not (autoval is null)))
	SET IDENTITY_INSERT WFM_DEF..DICTIONARY ON


if exists(select * from syscolumns where id = object_id('WFM_DEF..DICTIONARY') and (not (autoval is null)))
	SET IDENTITY_INSERT WFM_DEF..DICTIONARY OFF
------------------------------------------------------------------------------------------------

-----------------------------DEFINE----------------------------------------------------
if exists(select * from syscolumns where id = object_id('WFM_DEF..DEFINE') and (not (autoval is null)))
	SET IDENTITY_INSERT WFM_DEF..DEFINE ON


if exists(select * from syscolumns where id = object_id('WFM_DEF..DEFINE') and (not (autoval is null)))
	SET IDENTITY_INSERT WFM_DEF..DEFINE OFF
------------------------------------------------------------------------------------------------

-----------------------------DEFITEM----------------------------------------------------
if exists(select * from syscolumns where id = object_id('WFM_DEF..DEFITEM') and (not (autoval is null)))
	SET IDENTITY_INSERT WFM_DEF..DEFITEM ON

if exists(select * from syscolumns where id = object_id('WFM_DEF..DEFITEM') and (not (autoval is null)))
	SET IDENTITY_INSERT WFM_DEF..DEFITEM OFF
------------------------------------------------------------------------------------------------

GO
/****** Object:  StoredProcedure [dbo].[sp_exec_transaction]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Chanqing
-- Create date: 2007.07.15
-- Description:	exec sqls in transaction
-- =============================================
CREATE PROCEDURE [dbo].[sp_exec_transaction]
	@ExecStr varchar(4000) = null			-- 待执行 SQL 语句集
AS
BEGIN
	declare @retval int, @BeginTrans varchar(500), @EndTrans varchar(500)
	if isnull(@ExecStr, '') != '' begin
		begin transaction
		exec (@ExecStr)
		if @@error = 0 begin
			commit transaction
			set @retval = 0
		end
		else begin
			rollback
			set @retval = -1
		end
	end
	return @retval
END

GO
/****** Object:  StoredProcedure [dbo].[sp_fields_insert]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Chanqing
-- Create date: 20081028
-- Description:	字段字典统一定义
-- =============================================
CREATE PROCEDURE [dbo].[sp_fields_insert]
	-- Add the parameters for the stored procedure here
	@tabname varchar(20) = '*',
	@field varchar(20),
	@dispstr varchar(100),
	@fieldtype varchar(20) = '', 
	@fieldlen tinyint = 0, 
	@summary varchar(100) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	set @dispstr = case when isnull(@dispstr, '') = '' then @field else @dispstr end
	if not exists(select field from fields where tabname = @tabname and Field = @field) begin
		insert into Fields (TabName, Field, DispStr, FieldType, FieldLen, Summary, Enabled)
			values(@tabname, @field, @dispstr, @fieldtype, @fieldlen, @summary, 1)
	end
END

GO
/****** Object:  StoredProcedure [dbo].[sp_GenInsertSQL]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--================================================================
-- Author:		WuYiBin
-- Create date: 2010.8
-- Description:	以指定表内容生成 Insert into 语句
-- Example: exec sp_GenInsertSQL @tablename = 'wfm_def..modules'
--================================================================
CREATE PROCEDURE [dbo].[sp_GenInsertSQL] (@tablename varchar(256))
as
begin
declare @sql varchar(max)
declare @sqlValues varchar(max)
set @sql =' ('
set @sqlValues = 'values (''+'
select @sqlValues = @sqlValues + cols + ' + '','' + ' ,@sql = @sql + '[' + name + '],'
  from
     (select case
				when xtype in (35,99)      

                     then 'case when '+ name +' is null then ''NULL'' else '+''''''''' + ' + 'convert(varchar(max),'+ name + ')'+ '+''''''''' +' end'
                when xtype in (48,52,56,59,60,62,104,106,108,122,127)      

                     then 'case when '+ name +' is null then ''NULL'' else ' + 'cast('+ name + ' as varchar)'+' end'

                when xtype in (58,61)

                     then 'case when '+ name +' is null then ''NULL'' else '+''''''''' + ' + 'convert(varchar,'+ name +',21)'+ '+'''''''''+' end'

               when xtype in (167)

                     then 'case when '+ name +' is null then ''NULL'' else '+''''''''' + ' + 'replace('+ name+','''''''','''''''''''')' + '+'''''''''+' end'

                when xtype in (231)

                     then 'case when '+ name +' is null then ''NULL'' else '+'''N'''''' + ' + 'replace('+ name+','''''''','''''''''''')' + '+'''''''''+' end'

                when xtype in (175)

                     then 'case when '+ name +' is null then ''NULL'' else '+''''''''' + ' + 'cast(replace('+ name+','''''''','''''''''''') as Char(' + cast(length as varchar)  + '))+'''''''''+' end'

                when xtype in (239)

                     then 'case when '+ name +' is null then ''NULL'' else '+'''N'''''' + ' + 'cast(replace('+ name+','''''''','''''''''''') as Char(' + cast(length as varchar)  + '))+'''''''''+' end'

                else '''NULL'''

              end as Cols,name

         from syscolumns

        where id = object_id(@tablename)

      ) T
set @sql ='select ''INSERT INTO ['+ @tablename + ']' + left(@sql,len(@sql)-1)+') ' + left(@sqlValues,len(@sqlValues)-4) + ')'' from '+@tablename
--print @sql
exec (@sql)
end

GO
/****** Object:  StoredProcedure [dbo].[sp_get_act_types]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_get_act_types] 
AS
	select 1 TypeKey, '1:字段关联' TypeDisp
	union select 2 TypeKey, '2:模块关联' TypeDisp
	union select 3 TypeKey, '3:附加表' TypeDisp
	order by 1


GO
/****** Object:  StoredProcedure [dbo].[sp_get_actflag]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===================================================================================================================================
-- Author:		WuYiBin
-- Create date: 2009.1.24
-- Description:	获取action的执行状态及可执行的动作
-- Example: exec sp_get_actflag @TabName = 'wfm_biz..workforcectrl', @KeyName = 'ctrlid', @KeyValue = '128', @ModId = 'wfm.main.force'
-- ===================================================================================================================================
CREATE PROCEDURE [dbo].[sp_get_actflag]
	@TabName	varchar(50),		-- 表名
	@KeyName	varchar(30),		-- 字段名
	@KeyValue	varchar(30),		-- 字段值
	@ModId		varchar(20)			-- 模块名
AS

begin try
	declare @ExeSql varchar(4000), @ActFlag int
	
	create table #actflag(actflag int)

	set @ExeSql = 'insert into #actflag(actflag) select isnull(ActFlag, 0) from ' + @TabName + ' where ' + @KeyName + ' = ' + @KeyValue
	exec(@ExeSql)

	select top 1 @ActFlag = actflag from #actflag

	if @@rowcount = 1 begin
		select case @ActFlag & power(2, FlagLoc) when 0 then 0 else 1 end Execed, ActName ExecName, ActTitle ExecTitle, 
				case when (isnull(AllReady, 0) = 0 or (AllReady & @ActFlag) = AllReady)
					and (isnull(PartReady, 0) = 0 or (PartReady & @ActFlag) > 0)
					and (isnull(NotReady, 0) = 0 or (NotReady & @ActFlag) = 0)
				then 'actid:"' + rtrim(ActId) + '", popup:' + str(isnull(Popup, 0),1) + ', width:' + ltrim(str(isnull(Width, 0))) + ', height:' + ltrim(str(isnull(Height, 0)))
				else '' end Actexec
			from wfm_def..Action where ModId like '%' + @ModId + '%'
				and Enabled = 1
			order by FlagLoc
	end
	else begin
		select null Execed, null ExecTitle, null ActExec
	end
	drop table #actflag
end try
begin catch
	print '[sp_get_actflag](获取action的执行状态失败！)'
end catch

GO
/****** Object:  StoredProcedure [dbo].[sp_get_InsertSql]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =======================================================================================
-- Author:		Guozhi.Song
-- CREATE date: 2010.12.20
-- Description:	生成INSERT语句
/* 
Example:	
EXEC sp_get_InsertSql @dbName='wfm_def', 
	@tabList='Action,BaseInfo,CalendarSolarData,CallBack,DataWin,Chart,City,Country,
				Define,DefItem,Dictionary,District,Emails,ExtUsers,Fields,Sort,
				Flow where FlowId != 96,Node where FlowId != 96,Nation,
				Holidays where Nation=1,HotFields,Modules,PrivSort,PrivLoc,Query,
				Roles where Role=1 or Role=2 or Role=3 or Role=4,Service,State,Strings,Tables,Tags,
				TempItems,Template,TempRep,TplFileLib,TreeDef,TreeItem,
				Users where UserId = ''admin'',UserStyle,Version', 
	@IncludeIdentity=1, 
	@DeleteOldData=0		
	
EXEC sp_get_InsertSql @dbName='wfm_biz', 
	@tabList='Project where ProjectId=0,GROUPS  where GroupId = 0,
			 SKILLGROUP WHERE SkillGroup=0,
			 OPTREST,SAMPTYPE,SAMPITEM,SCHETYPE,
			 SITE WHERE SiteId=0,TIMESPAN,
			 POSTS,WORKTAG,SHIFTSORT where ProjectId=0',
	@IncludeIdentity=1, 
	@DeleteOldData=0
EXEC vxi_def..sp_get_InsertSql @dbName='vxi_ivr', 
	@tabList='FaxStatus', 
	@IncludeIdentity=1, 
	@DeleteOldData=0
*/
-- =======================================================================================
CREATE PROC [dbo].[sp_get_InsertSql]
	@dbName				VARCHAR(32)='',	--数据库名称 wfm_biz or wfm_def
	@tabList			VARCHAR(max),	--要导出数据的表名，表名之间用逗号隔开，过滤条件跟在表名后面，用空格隔开 如tab1 where col1!=2, tab2, tab3	
	@IncludeIdentity	BIT=1,			--是否包含自增字段
	@DeleteOldData		BIT=1			--插入前删除所有数据
AS
	DECLARE
		@index		INT, 
		@wi			INT,
		@SQL		VARCHAR(max),
		@SQL1		VARCHAR(max),
		@tabName	VARCHAR(128),
		@colName	VARCHAR(128),
		@colType	VARCHAR(128),
		@tabPrefix	VARCHAR(32),
		@cols		VARCHAR(max),
		@colsData	VARCHAR(max),
		@SQLWhere	VARCHAR(1024),		
		@SQLIdentityOn	VARCHAR(MAX),
		@SQLIdentityOff VARCHAR(MAX),
		@SQLDelete		VARCHAR(max),
		@SQLIfBegin		VARCHAR(1024),
		@SQLIfEnd		VARCHAR(1024),
		@SQLNull		VARCHAR(1024);		
	DECLARE @t_tb TABLE(TB varchar(128), Sqlwhere varchar(1024), SN BIGINT IDENTITY(1,1))
	DECLARE @tb TABLE(insert_sql VARCHAR(max), SN BIGINT IDENTITY(1,1));
	DECLARE @colList TABLE(colName VARCHAR(128), colType VARCHAR(128), 
		colValueL VARCHAR(120), colValueR VARCHAR(120), selColName VARCHAR(128));
	create table #t_tb(TB varchar(128), Sqlwhere varchar(1024), SN BIGINT)
BEGIN
	SET NOCOUNT ON
	SET @tabList = REPLACE(@tabList, CHAR(9), '')
	SET @tabList = REPLACE(@tabList, CHAR(10), '')
	SET @tabList = REPLACE(@tabList, CHAR(13), '')
	SET @dbName = LTRIM(RTRIM(@dbName))
	SET @index = CHARINDEX(',', @tabList)
	IF LEN(@dbName) > 0
		SET @tabPrefix = @dbName + '..'
	ELSE 
		SET @tabPrefix = '';	
	
	WHILE @index > 0 AND @index IS NOT NULL
	BEGIN
		SET @tabName = SUBSTRING(@tabList, 1, @index-1)
		 
		SET @wi=CHARINDEX(' where', LTRIM(@tabName))

		IF @wi=0
			SET @wi = LEN(@tabName)
				
		INSERT INTO @t_tb(tb, Sqlwhere) VALUES(SUBSTRING(@tabName, 1, @wi), SUBSTRING(@tabName, @wi+1, LEN(@tabName)-@wi))

		SET @tabList = SUBSTRING(@tabList, @index+1, LEN(@tabList)-@index)
		SET @index = CHARINDEX(',', @tabList)
	END

	IF @index = 0 OR @index IS NULL
		SET @tabName = @tabList
	ELSE 
		SET @tabName = SUBSTRING(@tabList, 1, @index)
	
	
	SET @wi=CHARINDEX(' where', LTRIM(@tabName))
	
	IF @wi=0
		SET @wi = LEN(@tabName)
	
	INSERT INTO @t_tb(tb, Sqlwhere) VALUES(SUBSTRING(@tabName, 1, @wi), SUBSTRING(@tabName, @wi+1, LEN(@tabName)-@wi))

	SELECT	@SQL1 = 'select INSERT_SQL='';SET NOCOUNT ON'+CHAR(13) + ''''+
					' union all '
	SELECT @SQLNull =	'select INSERT_SQL=''  '' union all ',		
		   @SQLIfBegin = 'select INSERT_SQL=''    If @Error=0 begin '''+
					' union all ',
		   @SQLIfEnd = ' union all ' + 'select INSERT_SQL=''    end;'''
	
	IF @dbName='wfm_biz' BEGIN
		DECLARE tab_cur CURSOR FOR 
		SELECT t.name, tb.Sqlwhere FROM wfm_biz.sys.tables t
		INNER JOIN @t_tb tb ON t.name=RTRIM(LTRIM(tb.TB))
		ORDER BY tb.SN
	END
	ELSE IF @dbName='wfm_def' BEGIN
		DECLARE tab_cur CURSOR FOR 
		SELECT t.name, tb.Sqlwhere FROM wfm_def.sys.tables t
		INNER JOIN @t_tb tb ON t.name=RTRIM(LTRIM(tb.TB))
		ORDER BY tb.SN
	END
	ELSE BEGIN
		insert into #t_tb select * from @t_tb
		
		declare @StrSql varchar(500)
		set @StrSql = '
			DECLARE tab_cur CURSOR FOR 
			SELECT t.name, tb.Sqlwhere FROM ' + @dbName + '.sys.tables t
			INNER JOIN #t_tb tb ON t.name=RTRIM(LTRIM(tb.TB))
			ORDER BY tb.SN'
		--print @StrSql --
		exec(@StrSql)
	END
	
	OPEN tab_cur
	FETCH NEXT FROM tab_cur INTO @tabName, @SQLWhere 
	WHILE @@FETCH_STATUS=0 BEGIN
		DELETE FROM @colList

		IF @dbName='wfm_biz' BEGIN
			IF NOT EXISTS(SELECT 1 FROM wfm_biz.sys.objects WHERE name=@tabName AND type='U') BEGIN
				PRINT(@tabName + N' 不存在1！')
				RAISERROR(@tabName, 16, -1);
				FETCH NEXT FROM tab_cur INTO @tabName, @SQLWhere
				CONTINUE;
			END
		
			INSERT INTO @colList(colName, colType, colValueL, colValueR)
			SELECT c.NAME, t.name, '',''
			FROM wfm_biz.sys.columns c
			INNER JOIN wfm_biz.sys.tables tab
				ON c.object_id = tab.object_id
			INNER JOIN wfm_biz.sys.types t
				ON c.user_type_id = t.user_type_id
			WHERE c.is_computed=0 
				AND tab.name = @tabName

			IF @IncludeIdentity=0
				DELETE FROM @colList WHERE colName IN(
					SELECT c.name FROM wfm_biz.sys.columns c
					INNER JOIN wfm_biz.sys.tables tab
						ON c.object_id = tab.OBJECT_ID
					WHERE is_identity=1)
		END
		ELSE IF @dbName='wfm_def' BEGIN
			IF NOT EXISTS(SELECT 1 FROM wfm_def.sys.objects WHERE name=@tabName AND type='U') BEGIN
				PRINT(@tabName + N' 不存在2！')
				RAISERROR(@tabName, 16, -1);
				FETCH NEXT FROM tab_cur INTO @tabName, @SQLWhere
				CONTINUE;
			END
			
			INSERT INTO @colList(colName, colType, colValueL, colValueR)
			SELECT c.NAME, t.name, '',''
			FROM wfm_def.sys.columns c
			INNER JOIN wfm_def.sys.tables tab
				ON c.object_id = tab.object_id
			INNER JOIN wfm_def.sys.types t
				ON c.user_type_id = t.user_type_id			
			WHERE c.is_computed=0 
				AND tab.name =@tabName

			IF @IncludeIdentity=0
				DELETE FROM @colList WHERE colName IN(
					SELECT c.name FROM wfm_def.sys.columns c
					INNER JOIN wfm_def.sys.tables tab
						ON c.object_id = tab.OBJECT_ID
					WHERE is_identity=1)
			
		END
		ELSE BEGIN
			IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE name=@tabName AND type='U') BEGIN
				PRINT(@tabName + N' 不存在3！')
				RAISERROR(@tabName, 16, -1);
				FETCH NEXT FROM tab_cur INTO @tabName, @SQLWhere
				CONTINUE;
			END
			
			INSERT INTO @colList(colName, colType, colValueL, colValueR)
			SELECT c.NAME, t.name, '',''
			FROM sys.columns c
			INNER JOIN sys.tables tab
				ON c.object_id = tab.object_id
			INNER JOIN sys.types t
				ON c.user_type_id = t.user_type_id
			WHERE c.is_computed=0 
				AND tab.name =@tabName

			IF @IncludeIdentity=0
				DELETE FROM @colList WHERE colName IN(
					SELECT name FROM sys.columns WHERE object_id = OBJECT_ID(@tabName) AND is_identity=1)
			
		END
	
		UPDATE @colList SET colValueL='RTRIM(', colValueR = ')' 
		WHERE colType IN('text', 'varchar', 'nvarchar', 'char', 'uniqueidentifier', 'datetime', 'nchar', 'sysname')
		
		SELECT @cols='', @colsData = '', @SQL = '';
		
		UPDATE @colList SET colName = '[' + colName + ']'	
		UPDATE @colList SET selColName=colName		
		
		UPDATE @colList SET colValueL='replace('+colValueL, colValueR = colValueR+','''''''','''''''''''')' 
		WHERE colType IN('text', 'varchar', 'nvarchar', 'char', 'nchar', 'sysname')	
			
		UPDATE @colList SET colValueL= 
			CASE WHEN colType IN('text', 'varchar', 'nvarchar', 'char', 'uniqueidentifier', 'datetime', 'nchar', 'sysname') THEN '''''''''+' ELSE '' END 
				+colValueL,
			colValueR = colValueR + CASE WHEN colType IN('text', 'varchar', 'nvarchar', 'char', 'nchar', 'datetime', 'uniqueidentifier', 'sysname') THEN '+''''''''' ELSE '' END 
				
		SELECT @cols = @cols + colName + ', ',
			@colsData = @colsData + 'isnull(' +
				colValueL +			
				CASE WHEN colType='datetime' THEN 'convert(varchar(20),'+colName+',120)'
				WHEN colType='uniqueidentifier'THEN 'convert(varchar(50),'+colName+')'
				WHEN colType='text'THEN 'convert(nvarchar(max),'+colName+')'
				WHEN colType='sysname'THEN 'convert(nvarchar(max),'+colName+')'
				WHEN colType='varbinary' OR colType='BINARY' OR colType='image' 
					THEN 'master.dbo.fn_varbintohexsubstring(1,'+colName+',1,0)'				
				ELSE  'cast('+colName+' as nvarchar(max))' END 
				+ colValueR + ',''null'')+'', ''+'
		FROM @colList

		SELECT @cols = LEFT(@cols, LEN(@cols)-1),
				@colsData = LEFT(@colsData, LEN(@colsData)-5),
				@SQL = 'select INSERT_SQL=''print ''''Table Name:  '+CHAR(9)+@tabName + ''''''''+
					' union all '
				--@colsNULL = LEFT(@colsNULL, LEN(@colsNULL)-1)
		
		SELECT @cols = 'select INSERT_SQL=''INSERT INTO ' + @tabPrefix + @tabName + '('+@cols+')',
			@colsData = '  VALUES(''+'+ @colsData + '+'');'' FROM '+ @tabPrefix + @tabName 
		SELECT @colsData = @colsData +' '+ ISNULL(@SQLWhere, '')
		--FROM @t_tb WHERE TB=@tabName

		IF @DeleteOldData=1	
			SET @SQLDelete = 'select INSERT_SQL='''' +
					''Delete from '+@tabPrefix + @tabName + '; '''+ 
					' union all '
		ELSE 
			SET @SQLDelete=''
		
		IF @IncludeIdentity=1 AND EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@tabName) AND is_identity=1)
		BEGIN
			SELECT @SQLIdentityOn = 'select INSERT_SQL=''SET IDENTITY_INSERT '+@tabPrefix + @tabName + ' ON;'''+
					' union all ',
				@SQLIdentityOff = ' union all ' + 'select INSERT_SQL=''SET IDENTITY_INSERT '+@tabPrefix + @tabName + ' OFF;'''
		END 
		ELSE 
		BEGIN
			SELECT @SQLIdentityOff = '',
				@SQLIdentityOn = '';
		END

		INSERT INTO @tb(insert_sql)
		EXECUTE(@SQLNull + @SQLIfBegin + @SQL+@SQLDelete+@SQLIdentityOn + @cols+@colsData + @SQLIdentityOff + @SQLIfEnd) 
	--PRINT @cols+@colsData	
		FETCH NEXT FROM tab_cur INTO @tabName, @SQLWhere
	END

	CLOSE tab_cur
	DEALLOCATE tab_cur
		
	SELECT insert_sql FROM @tb ORDER BY sn
	
	drop table #t_tb
END

GO
/****** Object:  StoredProcedure [dbo].[sp_get_modules]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_get_modules]
  @Module char(20) = NULL
 AS
  select * from Modules
    where ModId = isnull(@Module, ModId)
  /*
  select m.*, isnull(s.SubNum, 0) SubNum
    from Modules m left join ( 
        select Module, count(*) SubNum 
          from SubModules 
          where Module = isnull(@Module, Module)
          group by Module
      ) s on m.Module = s.Module
    where m.Module = isnull(@Module, m.Module)
  */
  /*
  if isnull(@Module, '') != '' begin
    select * from SubModules
      where Module = @Module
  end
  */



GO
/****** Object:  StoredProcedure [dbo].[sp_get_sort]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_get_sort]
  @SortId int = 0
AS
  if @SortId = 0
    select * from Sort 
		where Enabled = 1
		order by Sort01, Sort02, Sort03, Sort04, Sort05, Sort06
  else
    select * from Sort where SortId = @SortId and Enabled = 1
  return @@rowcount



GO
/****** Object:  StoredProcedure [dbo].[sp_get_sort_items]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_get_sort_items]

  @SortId int = 0,
  @Table varchar(32) = null,
  @MaxLines int = 0,
  @Order varchar(32) = null
AS
  declare @layer01 smallint, @layer02 smallint, @layer03 smallint, @layer04 smallint, @layer05 smallint, @layer06 smallint, @Retval int
 
  select @layer01 = 0, @layer02 = 0, @layer03 = 0, @layer04 = 0, @layer05 = 0, @layer06 = 0
  set @Table = rtrim(isnull(@Table, ''))
  set @Order = rtrim(isnull(@Order, ''))

  if isnull(@SortId, 0) != 0
    select @layer01 = Sort01, @layer02 = Sort02, @layer03 = Sort03, @layer04 = Sort04,
           @layer04 = Sort04, @layer05 = Sort05, @layer06 = Sort06
      from Sort
      where SortId = @SortId

  if @Table = '' begin
    select * from Sort 
      where Sort01 = case @Layer01 when 0 then Sort01 else @Layer01 end
        and Sort02 = case @Layer02 when 0 then Sort02 else @Layer02 end
        and Sort03 = case @Layer03 when 0 then Sort03 else @Layer03 end
        and Sort04 = case @Layer04 when 0 then Sort04 else @Layer04 end
        and Sort05 = case @Layer05 when 0 then Sort05 else @Layer05 end
        and Sort06 = case @Layer06 when 0 then Sort06 else @Layer06 end
  end
  else begin
    declare @ExecStr varchar(2000)
    if isnull(@MaxLines, 0) > 0 begin
      set @ExecStr = 'select top ' + ltrim(@MaxLines)
    end
    else begin
      set @ExecStr = 'select'
    end
    set @ExecStr = @ExecStr + ' c.Sort, c.HtmlFile, c.Leaf, t.*, c.Sort01, c.Sort02, c.Sort03, c.Sort04, c.Sort05, c.Sort06 from Sort c, ' + @Table + ' t where c.SortId = t.SortId'
  
    if @layer01 > 0 
      set @ExecStr = @ExecStr + ' and c.Sort01 = ' + ltrim(str(@layer01))

    if @layer02 > 0 
      set @ExecStr = @ExecStr + ' and c.Sort02 = ' + ltrim(str(@layer02))

    if @layer03 > 0 
      set @ExecStr = @ExecStr + ' and c.Sort03 = ' + ltrim(str(@layer03))

    if @layer04 > 0 
      set @ExecStr = @ExecStr + ' and c.Sort04 = ' + ltrim(str(@layer04))

    if @layer05 > 0 
      set @ExecStr = @ExecStr + ' and c.Sort05 = ' + ltrim(str(@layer05))

    if @layer06 > 0 
      set @ExecStr = @ExecStr + ' and c.Sort06 = ' + ltrim(str(@layer06))
    
    set @ExecStr = @ExecStr + ' order by c.sortId ' 
    if (@Order != '') set @ExecStr = @ExecStr + ', t.' + @Order
    --print @ExecStr
    exec (@ExecStr)
  end


GO
/****** Object:  StoredProcedure [dbo].[sp_get_sort_parent]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_get_sort_parent]
  @SortId int
AS
  declare @layer01 smallint, @layer02 smallint, @layer03 smallint, @layer04 smallint, @layer05 smallint, @layer06 smallint

  if isnull(@SortId, 0) != 0 begin
    select @layer01 = Sort01, @layer02 = Sort02, @layer03 = Sort03, @layer04 = Sort04, 
           @layer05 = Sort05, @layer06 = Sort06
      from Sort
      where SortId = @SortId
  end
  else begin
    select @layer01 = 0, @layer02 = 0, @layer03 = 0, @layer04 = 0, @layer05 = 0, @layer06 = 0
  end
 
  if @layer01 = 0
    select * from Sort
      where SortId = 0
  else if @layer02 = 0
    select * from Sort
      where Sort01 = @layer01
        and Sort02 = 0
    order by Sort01, Sort02, Sort03, Sort04, Sort05, Sort06 
  else if @layer03 = 0
    select * from Sort
      where Sort01 = @layer01
        and (Sort02 = 0 or Sort02 = @layer02)
        and Sort03 = 0
    order by Sort01, Sort02, Sort03, Sort04, Sort05, Sort06 
  else if @layer04 = 0
    select * from Sort
      where Sort01 = @layer01
        and (Sort02 = 0 or Sort02 = @layer02)
        and (Sort03 = 0 or Sort03 = @layer03)
        and Sort04 = 0
    order by Sort01, Sort02, Sort03, Sort04, Sort05, Sort06 
  else if @layer05 = 0
    select * from Sort
      where Sort01 = @layer01
        and (Sort02 = 0 or Sort02 = @layer02)
        and (Sort03 = 0 or Sort03 = @layer03)
        and (Sort04 = 0 or Sort04 = @layer04)
        and Sort05 = 0
    order by Sort01, Sort02, Sort03, Sort04, Sort05, Sort06 
  else if @layer06 = 0
    select * from Sort
      where Sort01 = @layer01
        and (Sort02 = 0 or Sort02 = @layer02)
        and (Sort03 = 0 or Sort03 = @layer03)
        and (Sort04 = 0 or Sort04 = @layer04)
        and (Sort05 = 0 or Sort05 = @layer05)
        and Sort06 = 0
    order by Sort01, Sort02, Sort03, Sort04, Sort05, Sort06 
  else begin
    select * from Sort
      where Sort01 = @layer01
        and (Sort02 = 0 or Sort02 = @layer02)
        and (Sort03 = 0 or Sort03 = @layer03)
        and (Sort04 = 0 or Sort04 = @layer04)
        and (Sort05 = 0 or Sort05 = @layer05)
        and (Sort06 = 0 or Sort06 = @layer06)
    order by Sort01, Sort02, Sort03, Sort04, Sort05, Sort06 
  end
  return @@rowcount




GO
/****** Object:  StoredProcedure [dbo].[sp_get_sort_table]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_get_sort_table]
  @SortId int = 0,
  @Table varchar(32) = null,
  @MaxLines int = 0,
  @Order varchar(32) = null
AS
  declare @layer01 smallint, @layer02 smallint, @layer03 smallint, @layer04 smallint, @layer05 smallint, @layer06 smallint, @Retval int
 
  select @layer01 = 0, @layer02 = 0, @layer03 = 0, @layer04 = 0, @layer05 = 0, @layer06 = 0
  set @Table = rtrim(isnull(@Table, ''))
  set @Order = rtrim(isnull(@Order, ''))

  if isnull(@SortId, 0) != 0
    select @layer01 = Sort01, @layer02 = Sort02, @layer03 = Sort03, 
           @layer04 = Sort04, @layer05 = Sort05, @layer06 = Sort06
      from Sort
      where SortId = @SortId

  declare @ExecStr varchar(2000)
  if isnull(@MaxLines, 0) > 0 begin
    set @ExecStr = 'select top ' + ltrim(@MaxLines)
  end
  else begin
    set @ExecStr = 'select '
  end

  set @ExecStr = @ExecStr + ' c.Sort, c.HtmlFile, c.Leaf, t.*, c.Sort01, c.Sort02, c.Sort03, c.Sort04, c.Sort05, c.Sort06 from Sort c, ' + @Table + ' t where c.SortId = t.SortId'
  
  if @layer01 > 0 
    set @ExecStr = @ExecStr + ' and c.Sort01 = ' + ltrim(str(@layer01))

  if @layer02 > 0 
    set @ExecStr = @ExecStr + ' and c.Sort02 = ' + ltrim(str(@layer02))

  if @layer03 > 0 
    set @ExecStr = @ExecStr + ' and c.Sort03 = ' + ltrim(str(@layer03))

  if @layer04 > 0 
    set @ExecStr = @ExecStr + ' and c.Sort04 = ' + ltrim(str(@layer04))

  if @layer05 > 0 
    set @ExecStr = @ExecStr + ' and c.Sort05 = ' + ltrim(str(@layer05))

  if @layer06 > 0 
    set @ExecStr = @ExecStr + ' and c.Sort06 = ' + ltrim(str(@layer06))
    
  if (@Order = '') 
    set @ExecStr = @ExecStr + ' order by c.sortId'
  else
    set @ExecStr = @ExecStr + ' order by ' + @Order

  print @ExecStr
  exec (@ExecStr)
  return @@rowcount



GO
/****** Object:  StoredProcedure [dbo].[sp_get_sortmode]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_get_sortmode]
AS
select * from sort s,modules m where s.sort02!=0  and s.sortid=m.sortid and m.enabled=1 order by  s.sort01 

print @@rowcount

return @@rowcount






GO
/****** Object:  StoredProcedure [dbo].[sp_get_submodules]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_get_submodules]
  @Module char(20),
  @SubModule char(20) = null
AS
  select * from SubModules
    where Module = @Module
      and SubModule = isnull(@SubModule, SubModule)



GO
/****** Object:  StoredProcedure [dbo].[sp_get_subsort]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_get_subsort]
  @SortId int = 0,
  @sub_layer_all bit = 0
AS
  declare @layer01 smallint, @layer02 smallint, @layer03 smallint, @layer04 smallint
  declare @layer05 smallint, @layer06 smallint, @layer smallint, @leaf bit
  if isnull(@SortId, 0) != 0 begin
    select @layer01 = Sort01, @layer02 = Sort02, @layer03 = Sort03, @layer04 = Sort04, 
           @layer05 = Sort05, @layer06 = Sort06, @leaf = leaf
      from Sort
      where SortId = @SortId
        and enabled = 1
  end
  else begin
    select @layer01 = 0, @layer02 = 0, @layer03 = 0, @layer04 = 0, @layer05 = 0, @layer06 = 0, @leaf = 1
  end
 
  if @layer01 = 0 
    select * from Sort
      where Sort01 != 0
        and Sort02 = case @sub_layer_all when 0 then 0 else Sort02 end
        and enabled = 1
      order by Sort01, Sort02, Sort03, Sort04, Sort05, Sort06
  else if @layer02 = 0
    select * from Sort
      where Sort01 = @layer01
        and Sort02 != 0
        and Sort03 = case @sub_layer_all when 0 then 0 else Sort03 end
        and enabled = 1
      order by Sort01, Sort02, Sort03, Sort04, Sort05, Sort06
  else if @layer03 = 0
    select * from Sort
      where Sort01 = @layer01
        and Sort02 = @layer02
        and Sort03 != 0
        and Sort04 = case @sub_layer_all when 0 then 0 else Sort04 end
        and enabled = 1
      order by Sort01, Sort02, Sort03, Sort04, Sort05, Sort06
  else if @layer04 = 0
    select * from Sort
      where Sort01 = @layer01
        and Sort02 = @layer02
        and Sort03 = @layer03
        and Sort04 != 0
        and Sort05 = case @sub_layer_all when 0 then 0 else Sort05 end
        and enabled = 1
      order by Sort01, Sort02, Sort03, Sort04, Sort05, Sort06
  else if @layer05 = 0
    select * from Sort
      where Sort01 = @layer01
        and Sort02 = @layer02
        and Sort03 = @layer03
        and Sort04 = @layer04
        and Sort05 != 0
        and Sort06 = case @sub_layer_all when 0 then 0 else Sort06 end
        and enabled = 1
      order by Sort01, Sort02, Sort03, Sort04, Sort05, Sort06
  else if @layer06 = 0
    select * from Sort
      where Sort01 = @layer01
        and Sort02 = @layer02
        and Sort03 = @layer03
        and Sort04 = @layer04
        and Sort05 = @layer05
        and Sort06 != 0
        and enabled = 1
      order by Sort01, Sort02, Sort03, Sort04, Sort05, Sort06
  else
    select * from Sort where @SortId < 0 and enabled = 1
  return @@rowcount




GO
/****** Object:  StoredProcedure [dbo].[sp_get_tree]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =======================================================================================
-- Author:		WuYiBin
-- Create date: 2010.10.15
-- Description:	返回查询树结构
/* Example: exec [dbo].[sp_get_tree] @TreeId=1 */
-- =======================================================================================
CREATE PROCEDURE [dbo].[sp_get_tree]
  @TreeId int = 0
AS
begin

	declare @Degree		tinyint,
			@Field01	varchar(50),
			@Field02	varchar(50),
			@Field03	varchar(50),
			@Field04	varchar(50),
			@Field05	varchar(50),
			@TreeURL	varchar(200),
			@ExSQL		varchar(2000)

	if exists(select 1 from TreeDef where TreeId = @TreeId and Enabled = 1) begin
		select @Degree = isnull(Degree, 1),
				@Field01 = isnull(Field01, ''),
				@Field02 = isnull(Field02, ''),
				@Field03 = isnull(Field03, ''),
				@Field04 = isnull(Field04, ''),
				@Field05 = isnull(Field05, ''),
				@TreeURL = isnull(TreeURL, '')
			from TreeDef
			where TreeId = @TreeId

		set @ExSQL = 'select distinct Item01 as ''' + @Field01 + ''''

		if @Degree >= 2 set @ExSQL = @ExSQL + ', Item02 as ''' + @Field02 + ''''
		if @Degree >= 3 set @ExSQL = @ExSQL + ', Item03 as ''' + @Field03 + ''''
		if @Degree >= 4 set @ExSQL = @ExSQL + ', Item04 as ''' + @Field04 + ''''
		if @Degree >= 5 set @ExSQL = @ExSQL + ', Item05 as ''' + @Field05 + ''''

		set @ExSQL = @ExSQL + ', isnull(ItemURL,''' + @TreeURL + ''') as URL'

		set @ExSQL = @ExSQL + ' from wfm_def..TreeItem where TreeId = ' + str(@TreeId)
		--print @ExSQL

		exec (@ExSQL)
	end	
end

GO
/****** Object:  StoredProcedure [dbo].[sp_get_user_sort]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_user_sort]
  @SortId int = 0
AS
  if @SortId = 0
    select * from Sort 
		where Enabled = 1
		order by Sort01, Sort02, Sort03, Sort04, Sort05, Sort06
  else
    select * from Sort where SortId = @SortId and Enabled = 1
  return @@rowcount

GO
/****** Object:  StoredProcedure [dbo].[sp_get_visit_priv]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_get_visit_priv]
AS
	select 1 PrivKey, '01:浏览' PrivDisp
	union select 3 PrivKey, '03:浏览+修改' PrivDisp
	union select 7 PrivKey, '07:浏览+修改+增删' PrivDisp
	union select 9 PrivKey, '09:浏览+确认' PrivDisp
	union select 11 PrivKey, '11:浏览+修改+确认' PrivDisp
	union select 15 PrivKey, '15:浏览+修改+增删+确认' PrivDisp
	order by 1



GO
/****** Object:  StoredProcedure [dbo].[sp_HotFields_setup]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_HotFields_setup]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

if exists(select * from syscolumns where id = object_id('HOTFIELDS') and (not (autoval is null)))
	SET IDENTITY_INSERT HOTFIELDS ON


if exists(select * from syscolumns where id = object_id('HOTFIELDS') and (not (autoval is null)))
	SET IDENTITY_INSERT HOTFIELDS OFF


END

GO
/****** Object:  StoredProcedure [dbo].[sp_job_setup]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_job_setup] AS


/****** Object:  Job [job_syn_stat_call_hourly]    Script Date: 05/23/2007 14:28:28 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/23/2007 14:28:29 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'job_syn_stat_call_hourly', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'无描述。', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [run_sp_syn_stat_call_hourly]    Script Date: 05/23/2007 14:28:29 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'run_sp_syn_stat_call_hourly', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET ARITHABORT ON;
execute vxi_ucd..sp_syn_stat_call_hourly', 
		@database_name=N'vxi_ucd', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'schedule_syn_stat_call_hourly', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20000101, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
	IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:






/*
-- 2006-7-17/12:53 上生成的脚本
-- 由: sa
-- 服务器: CHANQING

BEGIN TRANSACTION            
  DECLARE @JobID BINARY(16)  
  DECLARE @ReturnCode INT    
  SELECT @ReturnCode = 0     
IF (SELECT COUNT(*) FROM msdb.dbo.syscategories WHERE name = N'[Uncategorized (Local)]') < 1 
  EXECUTE msdb.dbo.sp_add_category @name = N'[Uncategorized (Local)]'

  -- 删除同名的警报（如果有的话）。
  SELECT @JobID = job_id     
  FROM   msdb.dbo.sysjobs    
  WHERE (name = N'vxi_ucd_daily_statistic')       
  IF (@JobID IS NOT NULL)    
  BEGIN  
  -- 检查此作业是否为多重服务器作业  
  IF (EXISTS (SELECT  * 
              FROM    msdb.dbo.sysjobservers 
              WHERE   (job_id = @JobID) AND (server_id <> 0))) 
  BEGIN 
    -- 已经存在，因而终止脚本 
    RAISERROR (N'无法导入作业“vxi_ucd_daily_statistic”，因为已经有相同名称的多重服务器作业。', 16, 1) 
    GOTO QuitWithRollback  
  END 
  ELSE 
    -- 删除［本地］作业 
    EXECUTE msdb.dbo.sp_delete_job @job_name = N'vxi_ucd_daily_statistic' 
    SELECT @JobID = NULL
  END 

BEGIN 

  -- 添加作业
  EXECUTE @ReturnCode = msdb.dbo.sp_add_job @job_id = @JobID OUTPUT , @job_name = N'vxi_ucd_daily_statistic', @owner_login_name = N'sa', @description = N'No description available.', @category_name = N'[Uncategorized (Local)]', @enabled = 1, @notify_level_email = 0, @notify_level_page = 0, @notify_level_netsend = 0, @notify_level_eventlog = 2, @delete_level= 0
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

  -- 添加作业步骤
  EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 1, @step_name = N'stat_login', @command = N'sp_stat_login', @database_name = N'vxi_ucd', @server = N'', @database_user_name = N'', @subsystem = N'TSQL', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 3, @on_fail_step_id = 0, @on_fail_action = 3
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 
  EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 2, @step_name = N'stat_call_report', @command = N'sp_stat_call_report', @database_name = N'vxi_ucd', @server = N'', @database_user_name = N'', @subsystem = N'TSQL', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'', @on_success_step_id = 0, @on_success_action = 1, @on_fail_step_id = 0, @on_fail_action = 2
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 
  EXECUTE @ReturnCode = msdb.dbo.sp_update_job @job_id = @JobID, @start_step_id = 1 

  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

  -- 添加作业调度
  EXECUTE @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id = @JobID, @name = N'vxi_stat', @enabled = 1, @freq_type = 4, @active_start_date = 20060101, @active_start_time = 60000, @freq_interval = 1, @freq_subday_type = 8, @freq_subday_interval = 1, @freq_relative_interval = 0, @freq_recurrence_factor = 0, @active_end_date = 99991231, @active_end_time = 235959
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

  -- 添加目标服务器
  EXECUTE @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @JobID, @server_name = N'(local)' 
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

END
COMMIT TRANSACTION          
GOTO   EndSave              
QuitWithRollback:
  IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION 
EndSave:
*/

GO
/****** Object:  StoredProcedure [dbo].[sp_links_setup]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_links_setup]
AS

if exists(select * from syscolumns where id = object_id('VXI_DEF..LINKS') and (not (autoval is null)))
	SET IDENTITY_INSERT VXI_DEF..LINKS ON

Insert into VXI_DEF..LINKS ([LinkId], [SortId], [Topic], [LinkTime], [ValidTime], [LinkFile], [WWW], [Acked], [Enabled]) 
Values (1, 20200000, 'VisionONE IVR Channel Settings', '2005-1-1', '2036-12-31', '', 'WebTools?method=search&mod=ivr.ch', 0, 1)

Insert into VXI_DEF..LINKS ([LinkId], [SortId], [Topic], [LinkTime], [ValidTime], [LinkFile], [WWW], [Acked], [Enabled]) 
Values (2, 20200000, 'VisionLog VRS Channel Settings', '2005-1-1', '2036-12-31', '', 'WebTools?method=search&mod=rec.ch', 0, 1)

if exists(select * from syscolumns where id = object_id('VXI_DEF..LINKS') and (not (autoval is null)))
	SET IDENTITY_INSERT VXI_DEF..LINKS OFF


GO
/****** Object:  StoredProcedure [dbo].[sp_lock_user]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_lock_user]
	@userid char(20)
AS
Begin
	if @userid = 'admin' or (select count(*) from users where userid=@userid) = 0 begin
		return 0
	end
	update users set locked='1', errtimes='0', actflag=0 where userid=@userid
End


GO
/****** Object:  StoredProcedure [dbo].[sp_modules_setup]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[sp_modules_setup]
AS
if exists(select * from syscolumns where id = object_id('WFM_DEF..MODULES') and (not (autoval is null)))
	SET IDENTITY_INSERT MODULES ON

if exists(select * from syscolumns where id = object_id('WFM_DEF..MODULES') and (not (autoval is null)))
	SET IDENTITY_INSERT MODULES OFF

GO
/****** Object:  StoredProcedure [dbo].[sp_oper_trace]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_oper_trace]
	@operator varchar(20),
	@operation varchar(4000)
AS
	if @operator is not null begin
		declare @maxid bigint, @newid bigint
		set @maxid = dbo.func_today()
		select @newid = isnull((select max(operid) from trace
			where operid < (@maxid + 1) * 10000000), @maxid * 10000000) + 1
		insert into trace values (@newid, @operator, getdate(), @operation)
	end



GO
/****** Object:  StoredProcedure [dbo].[sp_privloc_setup]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_privloc_setup]
AS
	-- 添加记录: dbo.privsort
	if (select count(*) from privsort) < 10 begin
		insert into privsort values (0, '{zh:系统环境类, en:Environment Configuration}', 1)
		insert into privsort values (10, '{zh:系统资源类, en:Resource Setting}', 1)
		insert into privsort values (20, '{zh:预测排班类, en:Forecast & Schedule}', 1)
		insert into privsort values (30, '{zh:班表管理类, en:Schedule Tables}', 1)
		insert into privsort values (40, '{zh:现场管理类, en:Schedule Realtime}', 1)
		insert into privsort values (50, '{zh:员工管理类, en:Agent Management}', 1)
		insert into privsort values (60, '{zh:系统保留60, en:Reserved 60}', 1)
		insert into privsort values (70, '{zh:系统保留70, en:Reserved 70}', 1)
		insert into privsort values (80, '{zh:系统保留80, en:Reserved 80}', 1)
		insert into privsort values (90, '{zh:系统保留90, en:Reserved 90}', 1)
	end

	-- 添加记录: dbo.privloc
	declare @privsort tinyint, @privloc tinyint, @subidx tinyint, @name nvarchar(200)
	select @privsort = 0, @privloc = 0, @subidx = 0, @name = '0'
	while @privloc < 100 begin
		select @privsort = @privloc - @privloc % 10, @subidx = @privloc % 10
		if not exists (select * from privloc where privloc = @privloc) begin
			if (@privloc >= 10) set @name = ''
			insert into privloc (privloc, privname, privsort, subidx, enabled) 
				values (@privloc, 'Loc:' + @name + ltrim(str(@privloc)), @privsort, @subidx, 1)
		end
		set @privloc = @privloc + 1
	end

GO
/****** Object:  StoredProcedure [dbo].[sp_query_list]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_query_list]
	-- Add the parameters for the stored procedure here
	@modid varchar(30),
	@methodtype tinyint, 
	@userid varchar(20)
AS
BEGIN
SELECT queryid, title, isnull(SchKey01,'')+
isnull(SchExp01,'')+
isnull(SchItem01,'')+
isnull(SchLogic01,'')+
isnull(SchKey02,'')+
isnull(SchExp02,'')+
isnull(SchItem02,'')+
isnull(SchLogic02,'')+
isnull(SchKey03,'')+
isnull(SchExp03,'')+
isnull(SchItem03,'')+
isnull(SchLogic03,'')+
isnull(SchKey04,'')+
isnull(SchExp04,'')+
isnull(SchItem04,'')+
isnull(SchLogic04,'')+
isnull(SchKey05,'')+
isnull(SchExp05,'')+
isnull(SchItem05,'')+
isnull(SchLogic05,'')+
isnull(SchKey06,'')+
isnull(SchExp06,'')+
isnull(SchItem06,'') as queryitems
  FROM [vxi_def].[dbo].[Query]
  WHERE modid = @modid and userid = @userid and method = @methodtype
  ORDER BY
		SaveTime, loadtime DESC
END

GO
/****** Object:  StoredProcedure [dbo].[sp_query_sch]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_query_sch]
	-- Add the parameters for the stored procedure here
	@queryid int
AS
BEGIN
SELECT *
  FROM [vxi_def].[dbo].[Query]
  WHERE queryid = @queryid
update [vxi_def].[dbo].[Query] set loadtime = getdate() WHERE queryid = @queryid
END

GO
/****** Object:  StoredProcedure [dbo].[sp_setup_record_process]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================================================================================
-- Author:		WuYiBin
-- Create date: 2009.3.17
-- Description:	生成信息表安装记录
-- Example: exec sp_setup_record_process @Tabname = 'wfm_def..links'
-- =================================================================================================================================
CREATE PROCEDURE [dbo].[sp_setup_record_process]
	@Tabname varchar(50)
as

begin try
declare @Keyname varchar(50), @ExeSql nvarchar(max), 
		@ExeSql1 nvarchar(max), @ExeSql2 nvarchar(max), 
		@ExeSql3 nvarchar(max), @keyvalue varchar(50)

select @Keyname = name from sys.columns 
	where object_id = object_id(@tabname) and column_id = 1

set @ExeSql1 = 'insert into ' + @tabname + '('
set @ExeSql2 = ''
select @ExeSql2 = @ExeSql2 + name + ',' from sys.columns 
	where object_id = object_id(@tabname)
	order by column_id
select @ExeSql2 = left(@ExeSql2, len(@ExeSql2) - 1) + ')'

IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#tmp_tab')) DROP TABLE #tmp_tab
create table #tmp_tab(keyname varchar(50), sqltext nvarchar(max), result_sqltext nvarchar(max))

set @ExeSql = ' select '+@Keyname+','+'''''''''+'
select @ExeSql = @ExeSql + case	when system_type_id = 35 then 'convert(varchar(max),' else '' end
						 + case	when system_type_id in (58,61) then 'convert(varchar,' else '' end
						 + case when is_nullable = 1 then 'isnull(' else '' end
						 + case	when system_type_id in (48,52,56,62,104,106,108,127) then 'rtrim(str(' else '' end
						+ name
						+ case when system_type_id in (48,52,56,62,104,106,108,127) then '))' else '' end
						+ case when is_nullable = 1 then 
								case when system_type_id in (58,61) then ', '''')' else ',''NULL'')' end
							else '' end
						+ case	when system_type_id in (58,61) then ',21)' else ''end
						+ case when system_type_id = 35 then ')' else '' end				
						+'+'''''''''+'+'',''''''+' from sys.columns where object_id = object_id(@tabname)
select @ExeSql = left(@ExeSql, len(@ExeSql) - 7)
select @ExeSql = 'insert into #tmp_tab(keyname, sqltext)' + @ExeSql + ' from ' + @tabname
print @ExeSql
exec (@ExeSql)

declare tmp_tab_cur cursor for
	select keyname from #tmp_tab
open tmp_tab_cur

fetch next from tmp_tab_cur into @keyvalue
while @@fetch_status = 0 begin
	set @ExeSql = @ExeSql1 + @ExeSql2 + ' select '
	set @ExeSql3 = ' where not exists(select 1 from ' + @tabname + ' where ' + @Keyname + ' = ''' + @keyvalue + ''');'
	select @ExeSql = @ExeSql + sqltext + @ExeSql3 from #tmp_tab where keyname = @keyvalue
	update #tmp_tab set result_sqltext = @ExeSql where keyname = @keyvalue
	fetch next from tmp_tab_cur into @keyvalue
end

close tmp_tab_cur
deallocate tmp_tab_cur

select result_sqltext from #tmp_tab
drop table #tmp_tab

end try
begin catch
	print '([sp_setup_record_process])(生成信息表初始安装记录失败！)'
	print Error_Message()
	return -1
end catch

GO
/****** Object:  StoredProcedure [dbo].[sp_sort_delete]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_sort_delete]
  @SortId int
AS
  if @SortId = 0
    delete from Sort
  else
    delete from Sort where SortId = @SortId
  return



GO
/****** Object:  StoredProcedure [dbo].[sp_sort_empty]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_sort_empty]
AS

  update agent set sortid = null
  update channels set sortid = null
  update devices set sortid = null
  update route set sortid = null
  update station set sortid = null

  delete from sort where Leaf = 1
  delete from sort where Leaf = 1
  delete from sort where Leaf = 1
  delete from sort where Leaf = 1
  delete from sort where Leaf = 1
  delete from sort where Leaf = 1


GO
/****** Object:  StoredProcedure [dbo].[sp_sort_insert]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_sort_insert]
	@parent_id int = 0,
	@SortId int = 0,
	@Sort varchar(100) = '',
	@Parent varchar(100) = '',
	@RootUrl varchar(50) = '',
	@HtmlFile varchar(50) = '',
	@Summary varchar (1000) = ''
AS
	if ltrim(isnull(@Sort, '')) = '' return
	declare @Sort01 smallint, @Sort02 smallint, @Sort03 smallint, @Sort04 smallint, @Sort05 smallint, @Sort06 smallint
	select @Sort01 = 0, @Sort02 = 0, @Sort03 = 0, @Sort04 = 0, @Sort05 = 0, @Sort06 = 0
  
	if @parent_id = 0 and isnull(@Parent, '') != '' begin
		select @parent_id = SortId from Sort where Sort = @Parent
	end

	if @parent_id < 0 begin
		set @parent_id = 0
	end

	if @SortId <= 0 begin
		set @SortId = 0
		if exists(select * from sort where sort = @Sort) begin
			select @SortId = SortId from sort where sort = @Sort
		end
	end
  
	if ltrim(isnull(@RootUrl, '') + isnull(@HtmlFile, '')) = '' begin  
		set @HtmlFile = 'PageSort.jsp'
	end

	if @parent_id = 0 begin
		-- New root Sort
		set @Sort01 = isnull((select max(Sort01) from Sort), 0) + 1
		select @Sort02 = 0, @Sort03 = 0, @Sort04 = 0
	end
	else begin 
		select @Sort01 = c.Sort01, @Sort02 = c.Sort02, @Sort03 = c.Sort03, 
        			@Sort04 = c.Sort04, @Sort05 = c.Sort05, @Sort06 = c.Sort06
			from Sort c 
			where c.SortId = @parent_id

		select  @Sort01 = isnull(@Sort01, 0), @Sort02 = isnull(@Sort02, 0), @Sort03 = isnull(@Sort03, 0), 
			@Sort04 = isnull(@Sort04, 0), @Sort05 = isnull(@Sort05, 0), @Sort06 = isnull(@Sort06, 0)

		if @Sort01 = 0 begin
			set @Sort01 = isnull((select max(Sort01) from Sort), 0) + 1
			select @Sort02 = 0, @Sort03 = 0, @Sort04 = 0
		end
		else if @Sort02 = 0 begin
			set @Sort02 = isnull((select max(Sort02) from Sort where Sort01 = @Sort01), 0) + 1
			select @Sort03 = 0, @Sort04 = 0
		end
		else if @Sort03 = 0 begin
			set @Sort03 = isnull((select max(Sort03) from Sort 
	                	where Sort01 = @Sort01
					and Sort02 = @Sort02), 0) + 1
			set @Sort04 = 0
		end
		else if @Sort04 = 0 begin
			set @Sort04 = isnull((select max(Sort04) from Sort 
                        	where Sort01 = @Sort01
					and Sort02 = @Sort02
					and Sort03 = @Sort03), 0) + 1
			set @Sort05 = 0
		end
		else if @Sort05 = 0 begin
			set @Sort05 = isnull((select max(Sort05) from Sort 
				where Sort01 = @Sort01
					and Sort02 = @Sort02
					and Sort03 = @Sort03
					and Sort04 = @Sort04), 0) + 1
			set @Sort06 = 0
		end
		else begin
			set @Sort06 = isnull((select max(Sort06) from Sort 
				where Sort01 = @Sort01
					and Sort02 = @Sort02
					and Sort03 = @Sort03
					and Sort04 = @Sort04
					and Sort05 = @Sort05), 0) + 1
		end
	end
  
	if isnull(@SortId, 0) = 0 begin
		set @SortId = @Sort01 * 10000000 + @Sort02 * 100000 + @Sort03 * 1000 + @Sort04 * 10 + @Sort05
	end
	else begin
		if (select count(*) from Sort where SortId = @SortId) > 0 begin
			raiserror 88862 ' There is error in the inserting process ! '
			return
		end
	end

	insert into Sort (SortId, Sort, Sort01, Sort02, Sort03, Sort04, Sort05, Sort06, RootUrl, HtmlFile, Leaf, Summary)
		values (@SortId, @Sort, @Sort01, @Sort02, @Sort03, @Sort04, @Sort05, @Sort06, @RootUrl, @HtmlFile, 1, @Summary)
	select @SortId SortId
	return @SortId

GO
/****** Object:  StoredProcedure [dbo].[sp_sort_move]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_sort_move]
  @sort varchar (100),
  @parent varchar(100)
AS

  declare @oldsortid int, @newsortid int

  select @oldsortid = sortid from sort where sort = @sort
  exec sp_sort_delete @sortid = @oldsortid
  exec sp_sort_insert @sort = @sort, @Parent = @parent
  select @newsortid = sortid from sort where sort = @sort
  update sort set htmlfile = 'templet' where sortid = @newsortid
  if @oldsortid != @newsortid begin
    update modules set sortid = @newsortid where sortid = @oldsortid 
    update Links set sortid = @newsortid where sortid = @oldsortid
  end


GO
/****** Object:  StoredProcedure [dbo].[sp_sort_setup]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[sp_sort_setup]
AS
 
	-- exec sp_sort_insert @sort = '{zh:收藏夹, en:Favorites}', @Parent = '', @HtmlFile = 'PageSort.jsp'

GO
/****** Object:  StoredProcedure [dbo].[sp_sort_setup_ch]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[sp_sort_setup_ch]
AS
  exec sp_sort_insert @sort = '系统维护', @Parent = '', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = '系统订制', @Parent = '系统维护', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = '帐号维护', @Parent = '系统维护', @HtmlFile = 'PageSort.jsp'

  exec sp_sort_insert @sort = '系统资源', @Parent = '', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = '电话资源', @Parent = '系统资源', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = '板卡资源', @Parent = '系统资源', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = '网络资源', @Parent = '系统资源', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = '资源分组', @Parent = '系统资源', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = '工程项目', @Parent = '系统资源', @HtmlFile = 'PageSort.jsp'

  exec sp_sort_insert @sort = 'VisionCTI记录', @Parent = '', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = '监控任务设置', @Parent = 'VisionCTI记录', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = '呼叫记录查询', @Parent = 'VisionCTI记录', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = '呼叫统计分析', @Parent = 'VisionCTI记录', @HtmlFile = 'PageSort.jsp'

  exec sp_sort_insert @sort = 'VisionIVR记录', @Parent = '', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = 'IVR 任务设置', @Parent = 'VisionIVR记录', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = 'IVR 记录查询', @Parent = 'VisionIVR记录', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = 'IVR 统计分析', @Parent = 'VisionIVR记录', @HtmlFile = 'PageSort.jsp'

  exec sp_sort_insert @sort = 'VisionLog记录', @Parent = '', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = '录音任务设置', @Parent = 'VisionLog记录', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = '录音记录查询', @Parent = 'VisionLog记录', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = '录音统计分析', @Parent = 'VisionLog记录', @HtmlFile = 'PageSort.jsp'

  exec sp_sort_insert @sort = 'VisionCRM记录', @Parent = '', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = '数据关联设置', @Parent = 'VisionCRM记录', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = 'CRM 记录查询', @Parent = 'VisionCRM记录', @HtmlFile = 'PageSort.jsp'
  exec sp_sort_insert @sort = 'CRM 统计分析', @Parent = 'VisionCRM记录', @HtmlFile = 'PageSort.jsp'

	update Sort set enabled = 0 where sort in ('系统订制', 'VisionCRM记录', '数据关联设置',
		'CRM 记录查询', 'CRM 统计分析')


GO
/****** Object:  StoredProcedure [dbo].[sp_sort_update]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_sort_update]
  @SortId int ,
  @Sort varchar(100) = null,
  @RootUrl varchar(50) = null,
  @HtmlFile varchar(50) = null,
  @Summary varchar(255) = null
AS
  if ltrim(@Sort) != '' begin
    update Sort 
      set Sort     = isnull(@Sort, Sort), 
          RootUrl  = isnull(@RootUrl, RootUrl),
          HtmlFile = isnull(@HtmlFile, HtmlFile),
          Summary       = isnull(@Summary, Summary)
      where SortId = @SortId
  end
  return



GO
/****** Object:  StoredProcedure [dbo].[sp_sql_paging]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =====================================================
-- Author:    <sunli@vxichina.com>
-- Create date: <2012.6.15>
-- Description:   <Description,,>
/* Example: 
exec [sp_sql_paging] @SchSql = 'select * from fields', @PageSize = 5, @Page = 1
   分页返回结果 包含 行号T_RowNum
   支持多表关联查询，及排序
*/
-- ====================================================
CREATE PROCEDURE [dbo].[sp_sql_paging]
	@SchSql	varchar(max),		-- 数据源查询语句
	@Page int = 1,				-- 页码
	@PageSize int = 50			-- 页尺寸
AS
BEGIN
	declare @SQLString nvarchar(max),
		@ParmDefine nvarchar(200),
		@TotalCount   bigint ,          -- 记录总数
		@Sql nvarchar(max),
		@OrderBy   nVARCHAR(200),                       --排序字段
		@BRowNum int,
		@ERowNum INT,
		@Columns nVARCHAR(2000);

	SELECT @BRowNum = (@Page - 1) * @PageSize, @ERowNum = @BRowNum + @PageSize;
    SET @SQLString = LTRIM(RTRIM(@SchSql))   
	
	-- 获取 select 字段，去除行号伪列
	-- SELECT  REPLACE (SUBSTRING ('select  a,b,c  from dual',1,CHARINDEX('from','select  a,b,c  from dual')-1),'select','')
    -- 结果 a,b,c
	SET @Columns = REPLACE (SUBSTRING (@SQLString,1,CHARINDEX('from',@SQLString)-1),'select','') 
	-- 去除 distinct
	SET @Columns= REPLACE (@Columns, 'distinct', '')
	-- 去除多表关联的表别名
	SET @Columns=dbo.func_regex_replace(@Columns, '[a-z][.]', '', 1, 1)  
	-- PRINT @Columns
	-- 如果查询sql有排序字段就按orderby字段排序  否则按查询第一列排序
    IF CHARINDEX('order by', @SQLString) > 0 BEGIN
		-- 解析查询语句中的排序字段
		SELECT @OrderBy=  substring (@SQLString,
				CHARINDEX('order by', @SQLString) + 8,
				LEN(@SQLString))
		-- 去掉@SQLString 中orderby 字段提高记录行数统计效率
		SET @SQLString  =  SUBSTRING (@SQLString,1,CHARINDEX('order by',@SQLString)-2)
	END
	ELSE BEGIN
		-- 取查询sql的第一列作为排序字段
		SET @OrderBy = SUBSTRING (@Columns, 1, CHARINDEX(',', @Columns + ',') - 1)
	END

	/*
	-- 去除orderby中的表别名
	-- print dbo.func_regex_replace('B.b1,b.b2,c.col', '[a-z][.]', 'a.', 1, 1)  
	-- 结果a.b1,a.b2,a.col
	CREATE FUNCTION dbo.func_regex_replace ( 
		@source ntext, --原字符串
		@regexp varchar(1000), --正则表达式
		@replace varchar(1000), --替换值
		@globalReplace bit = 1, --是否是全局替换
		@ignoreCase bit = 0 --是否忽略大小写
	) 
	*/

	IF CHARINDEX('.', @OrderBy) > 0	 BEGIN
		SET @OrderBy=dbo.func_regex_replace(@OrderBy, '[a-zA-Z]+[.]', 'a.', 1, 1)  
	END
	-- PRINT @OrderBy

    -- 获得记录数          
    Set @Sql = 'Select @RecordCount = Count(*) From  (' +  @SQLString + ' ) a ' ;
    EXEC sp_executesql @Sql, N'@RecordCount INT OUTPUT', @RecordCount = @TotalCount OUTPUT;
    -- PRINT  @TotalCount
    -- 分页
	SET @Sql = 
       'Select  TempT.* From (
            Select  a.*, ROW_NUMBER() Over(Order By ' + @OrderBy + ') As T_RowNum 
            From  (' + @SQLString + ' )a
        ) as TempT 
        Where T_RowNum > ' + Convert(varchar(10), @BRowNum) + ' 
              And 
              T_RowNum <= ' + Convert(varchar(10), @ERowNum)  ;
            --  Order By ' + @OrderBy;
	Exec(@Sql)
	return isnull(@TotalCount, 0)
END

GO
/****** Object:  StoredProcedure [dbo].[sp_syn_define]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		chanqing
-- Create date: 2007.07.26
-- Description:	功能定义同步
-- @host	: 远程数据库，如：[192.168.0.200].[wt_def]
-- @table	: 同步数据表
-- @key		: 同步关键字段
-- @type	: 同步操作类型，in 表示输入，out 表示输出
-- =============================================
CREATE PROCEDURE [dbo].[sp_syn_define]
	@type varchar(10) = 'in',
	@host varchar(100) = '[192.168.0.200].[wt_def]',
	@table varchar(50) = '',
	@key varchar(50) = ''
AS
BEGIN
	SET NOCOUNT ON

	-- use master
	-- exec sp_addlinkedserver '192.168.0.200'
	-- exec sp_addlinkedsrvlogin @rmtsrvname = '192.168.0.200', @useself = 'false', @rmtuser = 'sa', @rmtpassword = 'vxi'
	-- reconfigure

	declare @ExecSql varchar(1000), @src varchar(100), @tar varchar(100)
	
	if (@type = 'in') begin
		select @src = @host + '.[dbo].' + @table, @tar = @table
	end
	else if (@type = 'out') begin
		select @src = @table, @tar = @host + '.[dbo].' + @table
	end

	if @src != '' and @tar != '' and @key != '' begin
		set @ExecSql = 'insert into ' + @tar 
					 + ' select * from ' + @src
					 + ' where ' + @key + ' not in '
					 + ' ( select ' + @key + ' from ' + @tar + ' )'

		print @ExecSql
		exec (@ExecSql)
	end

	return

	/*
	exec sp_syn_define @type = 'in', @host = '[192.168.0.200].[cat_def]', @table = 'modules',		@key = 'modid'
	exec sp_syn_define @type = 'in', @host = '[192.168.0.200].[cat_def]', @table = 'action',		@key = 'actid'
	exec sp_syn_define @type = 'in', @host = '[192.168.0.200].[cat_def]', @table = 'define',		@key = 'keyid'
	exec sp_syn_define @type = 'in', @host = '[192.168.0.200].[cat_def]', @table = 'defitem',		@key = 'keyid'
	exec sp_syn_define @type = 'in', @host = '[192.168.0.200].[cat_def]', @table = 'dictionary',	@key = 'dicname'
	exec sp_syn_define @type = 'in', @host = '[192.168.0.200].[cat_def]', @table = 'HotFields',	@key = 'hotkey'
	exec sp_syn_define @type = 'in', @host = '[192.168.0.200].[cat_def]', @table = 'Links',		@key = 'linkid'
	exec sp_syn_define @type = 'in', @host = '[192.168.0.200].[cat_def]', @table = 'Flow',			@key = 'FlowId'
	exec sp_syn_define @type = 'in', @host = '[192.168.0.200].[cat_def]', @table = 'Node',			@key = 'FlowId'
	exec sp_syn_define @type = 'in', @host = '[192.168.0.200].[cat_def]', @table = 'DataWin',		@key = 'DataWin'
	exec sp_syn_define @type = 'in', @host = '[192.168.0.200].[cat_def]', @table = 'Pickup',		@key = 'PickId'

	exec sp_syn_define @type = 'out', @host = '[192.168.0.200].[cat_def]', @table = 'modules',		@key = 'modid'
	-- insert into [192.168.0.200].[cat_def].[dbo].modules select * from modules where modid not in  ( select modid from [192.168.0.200].[cat_def].[dbo].modules )

	*/

END

GO
/****** Object:  StoredProcedure [dbo].[sp_time_range]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_time_range]
	@recdate int = 0,	-- 格式：yyyymmdd，0：表示当月，dd=00：表示月报，mm=00：表示年报
	@time_beg datetime = null output,
	@time_end datetime = null output
AS
	declare @year int, @month int, @day int, @dayend varchar(20)

	if isnull(@recdate, 0) < 19800100 begin
		declare @date datetime
		select @date = datediff(mm, -1, getdate())
		select @year = year(@date), @month = month(@date), @day = 0
		select @recdate = @year * 10000 + @month + 100
	end
	else begin
		select @year = @recdate / 10000, @month = @recdate / 100 % 100, @day = @recdate % 100
	end

	set @dayend = ' 23:59:59'

	if @day != 0 begin
		-- date range is a day
		select @time_beg = str(@recdate), @time_end = str(@recdate) + @dayend
	end
	else if @month != 0 begin
		-- date range is a month
		set @time_beg = str(@recdate + 1)
		set @time_end = str(dbo.func_month_last(@time_beg)) + @dayend
	end
	else begin
		-- date range is a year
		select @time_beg = str(@recdate + 101), @time_end = str(@recdate + 1231) + @dayend
	end


GO
/****** Object:  StoredProcedure [dbo].[sp_unlock_user]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_unlock_user]
	@userid char(20)
AS
Begin
	if @userid = 'admin' or (select count(*) from users where userid=@userid) = 0 begin
		return 0
	end
	
	update users set locked='0', errtimes='0', actflag=0  where userid=@userid
	
End


GO
/****** Object:  StoredProcedure [dbo].[sp_update_favorite]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_update_favorite]
	-- Add the parameters for the stored procedure here
	@userid varchar(20), 
	@id int

AS
BEGIN
UPDATE [vxi_def].[dbo].[Favorite]
   SET 
      [VisitTime] = getdate()
 WHERE userid=@userid and FavorId = @id
select * from Favorite where userid=@userid and Enabled = 1
END

GO
/****** Object:  StoredProcedure [dbo].[sp_userstyle_insert]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_userstyle_insert]
	-- Add the parameters for the stored procedure here
  @UserId varchar(20) ,
  @ObjType smallint,
  @ObjId varchar(50),
  @Style text,
  @Index smallint
AS
BEGIN
--declare @strsql nvarchar(4000), @result int
	--print @Style
	if exists(select * from userstyle m where m.userid = @UserId and m.ObjType = @ObjType and m.objId = @ObjId)
		Update userstyle 
			set  style01 = case when @Index = 1 then @Style  else style01 end,
				 style02 = case when @Index = 2 then @Style  else style02 end,
			     style03 = case when @Index = 3 then @Style  else style03 end,
				 style04 = case when @Index = 4 then @Style  else style04 end,
				 style05 = case when @Index = 5 then @Style  else style05 end
			where userid = @UserId and ObjType = @ObjType and objId = @ObjId
	else 
	INSERT INTO [vxi_def].[dbo].[UserStyle]
           ([UserId]
           ,[ObjType]
           ,[ObjId]
           ,[Style01]
           ,[Style02]
           ,[Style03]
           ,[Style04]
           ,[Style05]
           ,[Enabled])
     VALUES
           (@UserId
           ,@ObjType
           ,@ObjId
           ,case when @Index = 1 then @Style end
           ,case when @Index = 2 then @Style end
           ,case when @Index = 3 then @Style end
           ,case when @Index = 4 then @Style end
           ,case when @Index = 5 then @Style end
           ,1)
	
	select * from userstyle m where m.userid = @UserId and m.ObjType = @ObjType and m.objId = @ObjId
	
END



GO
/****** Object:  StoredProcedure [dbo].[sp_vxi_init]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_vxi_init]
AS

	if not exists(select * from version where version = '3.0.0') begin
		insert into version (version, verdate)
			values ('3.0.0', year(getdate()) * 10000 + month(getdate()) * 100 + day(getdate()))
	end

	if not exists(select * from users where userid = 'admin') begin
		insert into roles (role, rolename, privilege, summary, acked, enabled)
			values (1, 'admin', 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF', 'Administrator', 1, 1)

		insert into roles (role, rolename, privilege, summary, acked, enabled)
			values (2, 'guest', '0000000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111', 'Guest', 1, 1)

		insert into roles (role, rolename, privilege, summary, acked, enabled)
			values (3, 'agent', '011100000000100001101100001000000000100000000000000000010000000000000000000000000F000000000000000000', 'agent', 1, 1)

		insert into roles (role, rolename, privilege, summary, acked, enabled)
			values (4, 'Supervisor', '0FFF000000000000000000000000000000000000000000000000000000000000000000FFFFFFFFF0F00FFFFFF0FF00000000', 'Supervisor', 1, 1)

		insert into users (UserId, UserName, Password, Role, DeptId, Acked, Enabled) 
			values ('admin', 'admin', 'admin', 1, 0, 1, 1)

		insert into users (UserId, UserName, Password, Role, DeptId, Acked, Enabled) 
			values ('guest', 'guest', 'guest', 2, 0, 1, 1)
	end

	if not exists (select sortid from sort) begin
		exec sp_sort_setup
	end

	if not exists (select modid from modules) begin
		exec sp_modules_setup
	end

	if not exists (select linkid from links) begin
		exec sp_links_setup
	end

	if not exists (select * from dictionary) begin
		exec sp_dict_setup
	end

--	if not exists (select * from vxi_sys..devtype) begin
--		exec vxi_sys..sp_devtype_setup
--	end
--
--	if not exists (select * from vxi_sys..grouptype) begin
--		exec vxi_sys..sp_grouptype_setup
--	end
--
--	if not exists (select * from vxi_sys..prjitemtype) begin
--		exec vxi_sys..sp_prjitem_type_setup
--	end
--
--	if not exists (select * from vxi_sys..chtype) begin
--		exec vxi_sys..sp_chtype_setup
--	end
--	
--	exec vxi_sys..sp_voicetype_setup

--	exec sp_action_setup

--	IF  EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N'vxi_ivr') begin
--		exec vxi_ivr..[sp_ivr_fax_setup]
--	end

	if not exists (select * from vxi_def..HotFields) begin
		exec wfm_def..sp_HotFields_setup
	end

	-- 生成Job
	exec sp_job_setup

GO
/****** Object:  StoredProcedure [dbo].[sp_vxidef_setup]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- ============================================================
-- Author:		WuYiBin
-- Create date: 2011.8.8
-- Description:	vxi_def 数据库信息初始化
-- Example: exec sp_vxidef_setup
-- ============================================================
CREATE PROCEDURE [dbo].[sp_vxidef_setup]
AS
begin try

	declare @Error	int

	set @Error = 0	
	SET NOCOUNT ON;

	begin TRAN
	ALTER table VXI_DEF..FLOW disable TRIGGER tr_flow_iu;      
    
   --start

  
    If @Error=0 begin 
print 'Table Name:   Sort'
Delete from vxi_def..Sort; 
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(10200000, '{en:Account Management, zh:帐号管理}', 1, 2, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 2, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(30302000, '{en:Agent Statistic Report, zh:坐席统计报表}', 3, 3, 2, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 23, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(30301000, '{en:Call Statistic Report, zh:呼叫统计报表}', 3, 3, 1, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 22, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(20200000, '{en:Channel Resources, zh:通道资源管理}', 2, 2, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 12, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(60200000, '{en:CRM Record Search, zh:CRM 记录查询}', 6, 2, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 30, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(60300000, '{en:CRM Record Statistic, zh:CRM 统计报表}', 6, 3, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 31, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(30200000, '{en:CTI Record Search, zh:CTI 记录查询}', 3, 2, 0, 0, 0, 0, null, '', 'PageSort.jsp', '', '', 1, 20, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(30300000, '{en:CTI Record Statistic, zh:CTI 统计报表}', 3, 3, 0, 0, 0, 0, null, '', 'PageSort.jsp', '', '', 0, 21, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(30400000, '{en:CTI Sys Report, zh:CTI系统报表}', 3, 4, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 26, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(50300000, '{en:Data Maintain,zh:数据维护}', 5, 3, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 43, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(60100000, '{en:Data Relation Setting, zh:数据关系设置}', 6, 1, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 29, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(30304000, '{en:Inbound Statistic Report, zh:呼入统计报表}', 3, 3, 4, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 25, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(40200000, '{en:IVR Record Search, zh:IVR记录查询}', 4, 2, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 30, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(40300000, '{en:IVR Report, zh:IVR统计报表}', 4, 3, 0, 0, 0, 0, null, '&nbsp;', 'PageSort.jsp', null, '', 1, null, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(40100000, '{en:IVR Task Setting, zh:IVR任务设置}', 4, 1, 0, 0, 0, 0, null, '', 'PageSort.jsp', '', '', 1, null, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(50500000, '{en:LOG Recording Sys Report, zh:LOG录音系统报表}', 5, 5, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 27, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(20600000, '{en:Media Connection Service, zh:媒体接入服务}', 2, 6, 0, 0, 0, 0, null, '', 'PageSort.jsp', '', '', 1, 16, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(30100000, '{en:Monitor Task Setting, zh:监控任务设置}', 3, 1, 0, 0, 0, 0, null, '', 'PageSort.jsp', '', '', 1, 19, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(20300000, '{en:Network Resources, zh:网络资源管理}', 2, 3, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 13, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(20500000, '{en:Project Management, zh:项目管理}', 2, 5, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 15, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(50200000, '{en:Recording Record Management, zh:录音记录管理}', 5, 2, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 42, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(50400000, '{en:Recording Statistic Report, zh:录音统计报表}', 5, 4, 0, 0, 0, 0, '', '', 'PageSort.jsp', null, null, 1, 44, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(50100000, '{en:Recording Task Setting, zh:录音任务设置}', 5, 1, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 41, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(10300000, '{en:Remote Link Setting, zh:远程资源}', 1, 3, 0, 0, 0, 0, '', '', 'PageSort.jsp', '', '', 1, 3, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(20400000, '{en:Resource Group, zh:资源分组管理}', 2, 4, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 14, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(30303000, '{en:Skill Statistic Report, zh:技能组统计报表}', 3, 3, 3, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 24, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(10100000, '{en:System Configration, zh:系统定制}', 1, 1, 0, 0, 0, 0, null, '', 'PageSort.jsp', '', '', 1, 1, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(20000000, '{en:System Resources, zh:系统资源}', 2, 0, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 0, 1, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(10000000, '{en:System Setting, zh:系统维护}', 1, 0, 0, 0, 0, 0, null, '', 'PageSort.jsp', '', '', 0, 1, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(20100000, '{en:Telephone Resources, zh:电话资源管理}', 2, 1, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 1, 11, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(60000000, '{en:VisionCRM, zh:VisionCRM接口}', 6, 0, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 0, 28, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(30000000, '{en:VisionCTI, zh:VisionCTI系统}', 3, 0, 0, 0, 0, 0, null, '', 'PageSort.jsp', '', '', 0, 1, 0, 0);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(40000000, '{en:VisionIVR, zh:VisionIVR系统}', 4, 0, 0, 0, 0, 0, null, '', 'PageSort.jsp', '', '', 0, 1, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(50000000, '{en:VisionLog, zh:VisionLog系统}', 5, 0, 0, 0, 0, 0, null, '', 'PageSort.jsp', '', '', 0, 1, 1, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(20700000, '{en:Word Package Manage, zh:词库管理}', 2, 7, 0, 0, 0, 0, null, '', 'PageSort.jsp', '', '', 1, 17, 0, 1);
INSERT INTO vxi_def..Sort([SortId], [Sort], [Sort01], [Sort02], [Sort03], [Sort04], [Sort05], [Sort06], [IconFile], [RootUrl], [HtmlFile], [IconCls], [Summary], [Leaf], [CtrlLoc], [Acked], [Enabled])  VALUES(70000000, '{zh:绩效报表, en:Performance Report}', 7, 0, 0, 0, 0, 0, null, '', 'PageSort.jsp', null, '', 0, 63, 0, 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   Action'
Delete from vxi_def..Action; 
INSERT INTO vxi_def..Action([ActId], [ActName], [ActTitle], [ModId], [SortId], [CtrlLoc], [AllReady], [PartReady], [NotReady], [Reverse], [FlagLoc], [FieldX], [ActType], [Fields], [MultiRec], [ActSQL], [ActSP], [OnAct], [OnTrue], [OnFalse], [Popup], [ActTab], [ActPage], [ActKey], [Params], [Width], [Height], [ExistSet], [SetFlag], [ResetFlag], [Visible], [Global], [Enabled])  VALUES('additem', '增加扩展数据', '增加扩展数据', 'rec.log', null, null, 0, 0, 0, 0, 1, null, 3, null, 0, null, 'vxi_rec..sp_recexts_insert !RecordId,!Handler,!Item01,!Item02,!Item03,!Item04,!Item05,!Item06,!Item07,!Item08,!Item09,!Item10,!Note,1', null, 'mod=favorites,method=search', null, null, null, null, null, null, null, null, null, null, 0, 1, null, 1);
INSERT INTO vxi_def..Action([ActId], [ActName], [ActTitle], [ModId], [SortId], [CtrlLoc], [AllReady], [PartReady], [NotReady], [Reverse], [FlagLoc], [FieldX], [ActType], [Fields], [MultiRec], [ActSQL], [ActSP], [OnAct], [OnTrue], [OnFalse], [Popup], [ActTab], [ActPage], [ActKey], [Params], [Width], [Height], [ExistSet], [SetFlag], [ResetFlag], [Visible], [Global], [Enabled])  VALUES('batpackage', 'batpackage', 'batpackage', 'rec.log', null, null, 0, 0, 0, null, 1, null, 5, null, null, null, null, null, null, null, 1, null, 'batpackage.jsp', 'com.vxichina.record.MultiDownload', '!recordid,!zippwd,!tflag', 400, 400, null, null, null, 1, null, 1);
INSERT INTO vxi_def..Action([ActId], [ActName], [ActTitle], [ModId], [SortId], [CtrlLoc], [AllReady], [PartReady], [NotReady], [Reverse], [FlagLoc], [FieldX], [ActType], [Fields], [MultiRec], [ActSQL], [ActSP], [OnAct], [OnTrue], [OnFalse], [Popup], [ActTab], [ActPage], [ActKey], [Params], [Width], [Height], [ExistSet], [SetFlag], [ResetFlag], [Visible], [Global], [Enabled])  VALUES('label', 'Label', 'Label', 'rec.log', 50100000, null, 0, 0, 0, null, 1, '', 3, 'Writer={user}, LabelTime={time}', 1, 'select * from vxi_rec..label', '', 'send=VisionCTI  send=VisionEMS  send=VisionLog', '', '', 1, 'vxi_rec..label', 'label.jsp', 'label', '', 420, 600, null, null, null, 1, null, 1);
INSERT INTO vxi_def..Action([ActId], [ActName], [ActTitle], [ModId], [SortId], [CtrlLoc], [AllReady], [PartReady], [NotReady], [Reverse], [FlagLoc], [FieldX], [ActType], [Fields], [MultiRec], [ActSQL], [ActSP], [OnAct], [OnTrue], [OnFalse], [Popup], [ActTab], [ActPage], [ActKey], [Params], [Width], [Height], [ExistSet], [SetFlag], [ResetFlag], [Visible], [Global], [Enabled])  VALUES('maintain', '{en:Data BackUp, zh:数据备份}', '{en:Data BackUp, zh:数据备份}', '', 50300000, 43, null, null, null, 0, 1, null, 5, null, null, null, null, null, null, null, 1, null, 'maintain.jsp', 'com.vxichina.record.Maintain', null, 320, 380, null, null, null, 1, null, 1);
INSERT INTO vxi_def..Action([ActId], [ActName], [ActTitle], [ModId], [SortId], [CtrlLoc], [AllReady], [PartReady], [NotReady], [Reverse], [FlagLoc], [FieldX], [ActType], [Fields], [MultiRec], [ActSQL], [ActSP], [OnAct], [OnTrue], [OnFalse], [Popup], [ActTab], [ActPage], [ActKey], [Params], [Width], [Height], [ExistSet], [SetFlag], [ResetFlag], [Visible], [Global], [Enabled])  VALUES('mk_dblink', '{zh:建立链接, en:Create Link}', '{zh:建立链接, en:Create Link}', 'dblink', 10100000, null, null, null, null, 0, 0, '', 3, '', null, '', 'sp_database_link_init @Host = !host, @LinkName = !dblink, @LogUser = !loguser, @LogPass = !logpass, @DbType = !dbtype', '', '', '', null, 'dblink', '', 'dblink', '', null, null, null, null, null, 1, null, 1);
INSERT INTO vxi_def..Action([ActId], [ActName], [ActTitle], [ModId], [SortId], [CtrlLoc], [AllReady], [PartReady], [NotReady], [Reverse], [FlagLoc], [FieldX], [ActType], [Fields], [MultiRec], [ActSQL], [ActSP], [OnAct], [OnTrue], [OnFalse], [Popup], [ActTab], [ActPage], [ActKey], [Params], [Width], [Height], [ExistSet], [SetFlag], [ResetFlag], [Visible], [Global], [Enabled])  VALUES('package', 'package', 'package', 'rec.log', 50000000, null, 0, 0, 0, null, 1, null, 5, null, 1, null, null, null, null, null, 1, null, 'package.jsp', 'com.vxichina.record.Download', '!recordid,!zippwd,!tflag', 400, 400, null, null, null, 1, null, 1);
INSERT INTO vxi_def..Action([ActId], [ActName], [ActTitle], [ModId], [SortId], [CtrlLoc], [AllReady], [PartReady], [NotReady], [Reverse], [FlagLoc], [FieldX], [ActType], [Fields], [MultiRec], [ActSQL], [ActSP], [OnAct], [OnTrue], [OnFalse], [Popup], [ActTab], [ActPage], [ActKey], [Params], [Width], [Height], [ExistSet], [SetFlag], [ResetFlag], [Visible], [Global], [Enabled])  VALUES('svc_link', '{zh:连接测试, en:Engine Detect}', '{zh:测试连接测试, en:Engine Service Detect}', 'service', null, null, null, null, null, 0, 0, null, 5, null, null, null, null, null, null, null, null, null, null, 'com.vxichina.model.Adapt', 'svc:!service, act:ONLINE, host:!host, port:!port, svctype:!svctype, clsname:!clsname, reload:!reload', null, null, 0, null, null, 1, null, 1);
INSERT INTO vxi_def..Action([ActId], [ActName], [ActTitle], [ModId], [SortId], [CtrlLoc], [AllReady], [PartReady], [NotReady], [Reverse], [FlagLoc], [FieldX], [ActType], [Fields], [MultiRec], [ActSQL], [ActSP], [OnAct], [OnTrue], [OnFalse], [Popup], [ActTab], [ActPage], [ActKey], [Params], [Width], [Height], [ExistSet], [SetFlag], [ResetFlag], [Visible], [Global], [Enabled])  VALUES('user_locked', 'user_locked', 'user_locked', 'users', 10000000, null, 0, 0, 4, 0, 2, null, 3, null, null, null, 'vxi_def..sp_lock_user |userid', null, 'mod=users,method=view,userid={userid}', null, null, null, null, null, null, null, null, 1, null, null, 1, null, 1);
INSERT INTO vxi_def..Action([ActId], [ActName], [ActTitle], [ModId], [SortId], [CtrlLoc], [AllReady], [PartReady], [NotReady], [Reverse], [FlagLoc], [FieldX], [ActType], [Fields], [MultiRec], [ActSQL], [ActSP], [OnAct], [OnTrue], [OnFalse], [Popup], [ActTab], [ActPage], [ActKey], [Params], [Width], [Height], [ExistSet], [SetFlag], [ResetFlag], [Visible], [Global], [Enabled])  VALUES('user_unlocked', 'user_unlocked', 'user_unlocked', 'users', 10000000, null, 0, 4, 8, 0, 3, null, 3, null, null, null, 'vxi_def..sp_unlock_user |userid', null, 'mod=users,method=view,userid={userid}', null, null, null, null, null, null, null, null, 1, null, null, 1, null, 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   BaseInfo'
Delete from vxi_def..BaseInfo; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   Calendar'
Delete from vxi_def..Calendar; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   CalendarSolarData'
Delete from vxi_def..CalendarSolarData; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   CallBack'
Delete from vxi_def..CallBack; 
SET IDENTITY_INSERT vxi_def..CallBack ON;
SET IDENTITY_INSERT vxi_def..CallBack OFF;
    end;
  
    If @Error=0 begin 
print 'Table Name:   Chart'
Delete from vxi_def..Chart; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   City'
Delete from vxi_def..City; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   Country'
Delete from vxi_def..Country; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   DataWin'
Delete from vxi_def..DataWin; 
INSERT INTO vxi_def..DataWin([DataWin], [dwTitle], [dwType], [KeyField], [KeySort], [GrpField], [StatFields], [dwSQL], [Rows], [Cols], [Fields], [FieldX], [Params], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [RowKey], [ColKey], [StatKey], [ViewPage], [EditMod], [EditTable], [EditFields], [EditSQL], [KeyPerson], [KeyGroup], [KeyDept], [Scripts], [Locks], [ExTpl], [Show3D], [AddLink], [LinkAge], [LinkPage], [LinkURL], [Acked], [Enabled])  VALUES('ftp.list', '{en:Enabled FTP List,zh:可用FTP列表}', 1, null, null, null, null, 'select m.station, s.ip, m.username, m.password from vxi_rec..Store m inner join vxi_sys..Station s on m.station = s.station    where m.enabled = 1', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, '1', null, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..DataWin([DataWin], [dwTitle], [dwType], [KeyField], [KeySort], [GrpField], [StatFields], [dwSQL], [Rows], [Cols], [Fields], [FieldX], [Params], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [RowKey], [ColKey], [StatKey], [ViewPage], [EditMod], [EditTable], [EditFields], [EditSQL], [KeyPerson], [KeyGroup], [KeyDept], [Scripts], [Locks], [ExTpl], [Show3D], [AddLink], [LinkAge], [LinkPage], [LinkURL], [Acked], [Enabled])  VALUES('label.list', '{en:Label List,zh:标签列表}', 1, '', '', null, null, 'select title, writer, labeltime, note from vxi_rec..label where recordid = !recordid order by label desc', 0, 0, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, '1', null, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..DataWin([DataWin], [dwTitle], [dwType], [KeyField], [KeySort], [GrpField], [StatFields], [dwSQL], [Rows], [Cols], [Fields], [FieldX], [Params], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [RowKey], [ColKey], [StatKey], [ViewPage], [EditMod], [EditTable], [EditFields], [EditSQL], [KeyPerson], [KeyGroup], [KeyDept], [Scripts], [Locks], [ExTpl], [Show3D], [AddLink], [LinkAge], [LinkPage], [LinkURL], [Acked], [Enabled])  VALUES('skill.in.ans.abn.hourly', '{zh:技能组呼入电话时段报表,en:Skill Inbound Hourly Statistic Report}', 2, null, null, null, null, 'vxi_rep..sp_stat_sd_skill_in_detail_ans_abn_report @Time_Begin=!datebeg, @Time_End=!dateend,  @preload=!preload, @stat=1, @language=!language', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, '1', null, null, null, null, null, null, null, null, null, null, null, null, null, null);
INSERT INTO vxi_def..DataWin([DataWin], [dwTitle], [dwType], [KeyField], [KeySort], [GrpField], [StatFields], [dwSQL], [Rows], [Cols], [Fields], [FieldX], [Params], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [RowKey], [ColKey], [StatKey], [ViewPage], [EditMod], [EditTable], [EditFields], [EditSQL], [KeyPerson], [KeyGroup], [KeyDept], [Scripts], [Locks], [ExTpl], [Show3D], [AddLink], [LinkAge], [LinkPage], [LinkURL], [Acked], [Enabled])  VALUES('stat.sd.trunk.in.report.daily', '{zh:中继呼入电话时段报表,en:Trunk Inbound Hourly Report}', 2, null, null, '', '', 'vxi_rep..sp_stat_sd_trunk_in_report @Time_Begin=!datebeg, @Time_End=!dateend', null, null, 'recdt={en:Date;zh:时间},groupid={en:Trunk;zh:中继组}', null, null, 'no', '', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, '1', null, null, null, null, null, null, null, null, null, null, null, null, null, null);
INSERT INTO vxi_def..DataWin([DataWin], [dwTitle], [dwType], [KeyField], [KeySort], [GrpField], [StatFields], [dwSQL], [Rows], [Cols], [Fields], [FieldX], [Params], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [RowKey], [ColKey], [StatKey], [ViewPage], [EditMod], [EditTable], [EditFields], [EditSQL], [KeyPerson], [KeyGroup], [KeyDept], [Scripts], [Locks], [ExTpl], [Show3D], [AddLink], [LinkAge], [LinkPage], [LinkURL], [Acked], [Enabled])  VALUES('svc.control', '{zh:应用服务列表, en:Application Service List}', 3, 'service', null, null, null, 'com.vxichina.model.Adapt svc:svc.ctrl, act:query, focus:list, fmt:!fmt, query:list, key=svclist, preload:!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..DataWin([DataWin], [dwTitle], [dwType], [KeyField], [KeySort], [GrpField], [StatFields], [dwSQL], [Rows], [Cols], [Fields], [FieldX], [Params], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [RowKey], [ColKey], [StatKey], [ViewPage], [EditMod], [EditTable], [EditFields], [EditSQL], [KeyPerson], [KeyGroup], [KeyDept], [Scripts], [Locks], [ExTpl], [Show3D], [AddLink], [LinkAge], [LinkPage], [LinkURL], [Acked], [Enabled])  VALUES('ucd.call', 'UCD Call List', 1, '', null, null, null, 'select s.subid, s.Calling, s.Called, s.Answer, s.Agent, s.Trunk, s.OnCallBegin, s.OnRing, s.OnEstb, s.OnCallEnd from vxi_ucd..ucd m inner join vxi_ucd..ucdcall s on m.ucdid = s.ucdid where m.ucdid = !ucdid order by s.subid', 0, 0, 'ucdid=UCDID, Calling=Calling No., Called=Called No., Answer=Answered No, Route=Route, Skill=Skill, Trunk=Trunk, StartTime=StartTime, TimeLen=TimeLen, Inbound=Inbound, Outbound=Outbound, Extension=Extension, Agent=Agent, UcdDate=UcdDate, UcdHour=UcdHour, PrjId=Project ID, UUI=UUI, subid=Sub., CallId=Call ID, Type=Type, CtrlDev=CtrlDev, OnCallBegin=OnCallBegin, OnRoute=OnRoute, OnSkill=OnSkill, OnRing=OnRing, OnEstb=OnEstb, OnHold=OnHold, OnRetv=OnRetv, OnTrans=OnTrans, OnConf=OnConf, OnConfEnd=OnConfEnd, OnCallEnd=OnCallEnd, OnOverflow=OnOverflow, OnAcwEnd=OnAcwEnd, UCID=UCID, UUI=UUI', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, '0', '1', null, null, null, null, null, null, null, null, null, null, null, null, null, null);
INSERT INTO vxi_def..DataWin([DataWin], [dwTitle], [dwType], [KeyField], [KeySort], [GrpField], [StatFields], [dwSQL], [Rows], [Cols], [Fields], [FieldX], [Params], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [RowKey], [ColKey], [StatKey], [ViewPage], [EditMod], [EditTable], [EditFields], [EditSQL], [KeyPerson], [KeyGroup], [KeyDept], [Scripts], [Locks], [ExTpl], [Show3D], [AddLink], [LinkAge], [LinkPage], [LinkURL], [Acked], [Enabled])  VALUES('ucd.item', 'UCD Call Parties', 1, '', null, null, null, 'select partyid, device, phone, agent, bRing, bEstb, Enter, Establish, Leave    from vxi_ucd..ucditem where ucdid = !ucdid order by partyid', 0, 0, 'partyid=Party ID, device=Device, phone=Phone No., agent=Agent, bRing=Ring, bEstb=Answered, Enter=Ring Time, Establish=Estb. Time, Leave=Leave Time', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, '0', '1', null, null, null, null, null, null, null, null, null, null, null, null, null, null);
INSERT INTO vxi_def..DataWin([DataWin], [dwTitle], [dwType], [KeyField], [KeySort], [GrpField], [StatFields], [dwSQL], [Rows], [Cols], [Fields], [FieldX], [Params], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [RowKey], [ColKey], [StatKey], [ViewPage], [EditMod], [EditTable], [EditFields], [EditSQL], [KeyPerson], [KeyGroup], [KeyDept], [Scripts], [Locks], [ExTpl], [Show3D], [AddLink], [LinkAge], [LinkPage], [LinkURL], [Acked], [Enabled])  VALUES('ucd.list', '{en:Associate Records,zh:关联记录}', 1, null, null, null, null, 'select m.recordid, m.Calling, m.Called, m.TimeLen from vxi_rec..records m where m.ucdid in (select s.ucdid from vxi_rec..records s where s.recordid = !recordid and s.finished >= 1 and s.ucdid>0 and s.timelen >= 1000) and m.finished >= 1 and m.timelen >= 1000', 0, 0, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, '1', null, null, null, null, null, null, null, null, null, null, null, null, null, 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   DbLink'
Delete from vxi_def..DbLink; 
INSERT INTO vxi_def..DbLink([DbLink], [Host], [LogUser], [LogPass], [DbType], [SplitKey], [SplitValue], [Summary], [ActFlag], [Enabled])  VALUES('vxi_sys', '172.28.19.224', 'sa', 'Esbu@2012', 1, '', '', '', 1, 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   Define'
Delete from vxi_def..Define; 
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(1, 'Enabled', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(2, 'SvcType', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(3, 'CallType', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(4, 'UcdType', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(5, 'date_group', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(6, 'SkillType', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(7, 'ExpType', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(8, 'boolean', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(10, 'Week', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(11, 'Month', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(12, 'timetype', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(13, 'taskflag', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(14, 'quality', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(15, 'state', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(20, 'itemkv', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(32, 'dwType', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(100, 'Percent', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(114, 'AgentStatus', '', null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(143, 'period', '', null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(154, 'schkeyname', null, null, 1);
INSERT INTO vxi_def..Define([KeyID], [KeyName], [Aliases], [SortField], [Enabled])  VALUES(158, 'bestb', null, null, 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   DefItem'
Delete from vxi_def..DefItem; 
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(1, '0', '{zh:禁用,en:Disabled}', null, 0);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(1, '1', '{zh:启用,en:Enabled}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(2, '0', 'Empty', null, 0);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(2, '1', 'TCP', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(2, '2', 'UDP', null, 2);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(2, '3', 'TCP + UDP', null, 3);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(2, '4', 'Corba', null, 4);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(2, '5', 'Corba + TCP', null, 5);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(2, '6', 'Corba + UDP', null, 6);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(2, '7', 'Corba + TCP + UDP', null, 7);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(3, '0', '{zh:内部呼叫,en: Inner}', null, 0);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(3, '1', '{zh:呼入,en:Inbound}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(3, '2', '{zh:呼出,en:Outbound}', null, 2);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(4, '1', 'Call', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(4, '2', 'Email', null, 2);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(4, '3', 'Fax', null, 3);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(4, '4', 'Chat', null, 4);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(4, '5', 'SMS', null, 5);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(5, 'day', '{zh:日报;en:Day}', null, 0);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(5, 'hour', '{zh:时报;en:Hour}', null, 4);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(5, 'month', '{zh:月报;en:month}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(5, 'week', '{zh:周报;en:week}', null, 2);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(5, 'year', '{zh:年报;en:year}', null, 3);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(6, '1', '{zh:呼叫;en:Call}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(6, '16', '{zh:Chat;en:Chat}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(6, '2', '{zh:QQ服务;en:QQ}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(6, '4', '{zh:邮件;en:EMail}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(6, '8', '{zh:短消息;en:SMS}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(7, 'equal', '{en:Equals,zh:等于}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(7, 'like', '{en:Like,zh:包含}', null, 2);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(8, '0', '{en:No,zh:否}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(8, '1', '{en:Yes,zh:是}', null, 2);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(10, '0', '{zh:星期日; en:Sunday}', null, 0);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(10, '1', '{zh:星期一; en:Monday}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(10, '2', '{zh:星期二; en:Tuesday}', null, 2);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(10, '3', '{zh:星期三; en:Wednesday}', null, 3);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(10, '4', '{zh:星期四; en:Thursday}', null, 4);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(10, '5', '{zh:星期五; en:Friday}', null, 5);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(10, '6', '{zh:星期六; en:Saturday}', null, 6);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '0', '1st', null, 0);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '1', '2nd', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '10', '11th', null, 10);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '11', '12th', null, 11);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '12', '13th', null, 12);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '13', '14th', null, 13);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '14', '15th', null, 14);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '15', '16th', null, 15);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '16', '17th', null, 16);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '17', '18th', null, 17);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '18', '19th', null, 18);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '19', '20th', null, 19);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '2', '3th', null, 2);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '20', '21th', null, 20);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '21', '22th', null, 21);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '22', '23th', null, 22);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '23', '24th', null, 23);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '24', '25th', null, 24);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '25', '26th', null, 25);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '26', '27th', null, 26);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '27', '28th', null, 27);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '28', '29th', null, 28);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '29', '30th', null, 29);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '3', '4th', null, 3);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '30', '31th', null, 30);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '4', '5th', null, 4);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '5', '6th', null, 5);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '6', '7th', null, 6);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '7', '8th', null, 7);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '8', '9th', null, 8);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(11, '9', '10th', null, 9);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(12, '1', 'Period', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(12, '2', 'Daily', null, 2);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(12, '3', 'Weekly', null, 3);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(12, '4', 'Monthly', null, 4);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(13, '1', 'Voice', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(13, '2', 'Video', null, 2);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(13, '3', 'Voice+Video', null, 3);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(14, '1', 'Low', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(14, '2', 'Middle', null, 2);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(14, '3', 'High', null, 3);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(15, '0', '{zh:关闭,en:Close}', null, 0);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(15, '1', '{zh:打开,en:Open}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(20, '1', '{en:Item01,zh:扩展1}', null, null);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(20, '2', '{en:Item02,zh:扩展2}', null, null);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(20, '3', '{en:Item03,zh:扩展3}', null, null);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(32, '1', 'SQL查询', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(32, '2', '存贮过程', null, 2);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(100, '0', '0 %', null, 0);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(100, '10', '10 %', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(100, '100', '100 %', null, 10);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(100, '20', '20 %', null, 2);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(100, '30', '30 %', null, 3);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(100, '40', '40 %', null, 4);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(100, '50', '50 %', null, 5);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(100, '60', '60 %', null, 6);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(100, '70', '70 %', null, 7);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(100, '80', '80 %', null, 8);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(100, '90', '90 %', null, 9);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(114, '0', '{zh:登出,en:Logout}', null, 0);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(114, '1', '{zh:登录,en:Login}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(114, '3', '{zh:就绪,en:Ready}', null, 3);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(114, '5', '{zh:话后工作,en:Acw}', null, 5);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(143, 'daily', '{zh:日期报表, en:Daily Report}', null, 2);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(143, 'hourly', '{zh:时段报表, en:Hourly Report}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(143, 'monthly', '{zh:月度报表, en:Monthly Report}', null, 4);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(154, 'agent', '{zh:坐席,en:Agent}', null, 4);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(154, 'skill', '{zh:技能,en:Skill}', null, 1);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(158, '0', '{zh:否, en:No}', null, 0);
INSERT INTO vxi_def..DefItem([KeyID], [KeyField], [KeyValue], [KeySort], [KeyOrder])  VALUES(158, '1', '{zh:是, en:Yes}', null, 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   Dictionary'
Delete from vxi_def..Dictionary; 
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('agent', 'vxi_sys..agent', null, 'agent', 'agentname', 'agent', 'enabled = 1', null, 'select s.agent, rtrim(s.agent) + ''('' + rtrim(isnull(agentname, rtrim(s.agent))) + '')'' agentname      from vxi_sys..agent s       where  s.enabled = 1      order by s.agent', 0, 1, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('agentgroupid', 'vxi_sys..groups', null, 'groupid', 'groupname', 'groupid', 'grouptype = 1 and enabled = 1', null, null, 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('agentlist', 'vxi_sys..agent', '', 'agent', 'agent', 'agent', 'enabled = 1', null, null, 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('agtgrp', 'vxi_sys..groups', null, 'groupid', 'groupname', 'groupname', 'enabled = 1 and grouptype = 1', null, 'select groupid, groupname from vxi_sys..groups where grouptype=1 and enabled = 1 order by groupname', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('AsrPkgs', 'vxi_rec...Package', '', 'pkgid', 'description', '', 'enabled = 1', '', 'select pkgid, rtrim(pkgid) + ''('' + rtrim(isnull(description, rtrim(description))) + '')'' description   from vxi_rec.asr.Package where enabled = 1 and pkgid > 0  union select 0 pkgid, ''------''    order by 1', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('AutoBackup', '', null, 'keyfield', 'keyvalue', 'keyfield', '', null, 'select d.keyfield, d.keyvalue from define m left join defitem d on m.keyid = d.keyid where m.keyid = 8', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('channel', 'vxi_sys..channels', null, 'channel', 'channel', 'channel', 'enabled = 1', null, null, 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('chtype', 'vxi_sys..chtype', null, 'chtype', 'typename', 'chtype', '', null, null, 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('clauseid', 'vxi_rec.asr.clauses', null, 'clauseid', 'decription', 'clauseid', 'enabled = 1', null, null, 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('cti_dev_type', 'sort', null, 'sortid', 'sort', 'sortid', 'sort01 = 1 and sort02 = 1 and sort03 != 1 and enabled = 1', null, null, 0, 1, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('devtype', 'vxi_sys..devtype', null, 'devtype', 'typename', 'devtype', '', null, null, 0, 1, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('Encry', '', null, 'keyfield', 'keyvalue', 'keyfield', null, null, 'select d.keyfield, d.keyvalue from define m left join defitem d on m.keyid = d.keyid where m.keyid = 8', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('ext', 'vxi_sys..devices', '', 'device', 'device', 'device', 'enabled = 1', null, null, 0, 1, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('extgrp', 'vxi_sys..groups', null, 'groupid', 'groupname', 'groupname', 'enabled = 1 and grouptype = 2', null, 'select groupid, groupname from vxi_sys..groups where grouptype=2 and enabled = 1 order by groupname', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('extlist', 'vxi_sys..devices', '', 'device', 'device', 'device', 'enabled = 1', null, null, 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('flowid', 'flow', '', 'flowid', 'flowtitle', 'flowid', 'enabled=1', null, '', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('ftpid', '', '', 'ftpid', 'station', '', '', null, 'select ftpid, station from vxi_rec..store where enabled = 1  union select ''0'','''' order by 1', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('groupid', 'vxi_sys..groups', null, 'groupid', 'groupname', 'groupid', 'enabled = 1', null, null, 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('grouptype', 'vxi_sys..grouptype', null, 'grouptype', 'typename', 'grouptype', '', null, '', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('ivr_ch', '', null, 'chtype', 'typename', '', '', null, 'select chtype, typename from vxi_sys..chtype where chtype / 16 = 1 order by chtype', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('ivrflow', 'vxi_ivr..IvrFlow', null, 'flowid', 'flowname', 'flowid', '', null, null, 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('logtype', 'vxi_def.dbo.ExtUsers', null, 'ExtPrefix', 'ExtTitle', 'ExtPrefix', null, null, 'select 0 ExtId, ''usr'' ExtPrefix, ''{zh:正常登录, en:Normal Login}'' ExtTitle  union select ExtId, ExtPrefix, ExtTitle      from vxi_def.dbo.ExtUsers      where enabled = 1      order by 1', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('mapped', '', null, 'keyfield', 'keyvalue', 'keyfield', null, null, 'select d.keyfield, d.keyvalue from define m left join defitem d on m.keyid = d.keyid where m.keyid = 8', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('modid', 'modules', null, 'modid', 'modname', 'modname', 'enabled = 1', null, null, 0, 1, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('pds_ch', 'vxi_sys..chtype', '', 'chtype', 'typename', '', null, null, 'select chtype, typename from vxi_sys..chtype where chtype / 16 = 4 order by chtype', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('prjid', 'vxi_sys..projects', null, 'prjid', 'project', 'prjid', 'enabled = 1', null, '', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('prjitemtype', 'vxi_sys..prjitemtype', null, 'type', 'typename', 'type', '', null, null, 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('projectid', 'vxi_sys..projects', null, 'prjid', 'project', 'prjid', 'enabled = 1', null, null, 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('rec_ch', '', null, 'chtype', 'typename', '', '', null, 'select chtype, typename from vxi_sys..chtype where chtype / 16 = 2 order by chtype', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('recstorage', '', '', 'ftpid', 'station', '', '', null, 'select ftpid, station from vxi_rec..store where type=3 or type=1', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('role', 'roles', null, 'role', 'rolename', 'role', 'enabled = 1', null, null, 0, 1, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('route', 'vxi_sys..route', null, 'route', 'routename', 'route', 'enabled = 1', null, null, 0, 1, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('routes', 'vxi_sys..route', null, 'route', 'routename', 'route', 'enabled = 1', null, null, 0, 1, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('scrstorage', 'vxi_rec..store', '', 'ftpid', 'station', '', '', null, 'select ftpid, station from vxi_rec..store where type=3 or type=2', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('service', 'service', null, 'service', 'service', '', 'enabled = 1 and service !=''svc.ctrl''', null, null, 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('skill', 'vxi_sys..skill', null, 'skill', 'skillname', 'skill', 'enabled = 1', null, 'select skill, rtrim(skill) + ''('' + isnull(rtrim(skillname), rtrim(skill)) +'')''  skillname from vxi_sys..skill where enabled = 1 order by skill', 0, 1, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('skilllist', 'vxi_sys..skill', '', 'skill', 'skillname', 'skill', 'enabled = 1', null, null, 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('skills', 'vxi_sys..skill', null, 'skill', 'skillname', 'skill', 'enabled = 1', null, null, 0, 1, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('sortid', 'sort', null, 'sortid', 'sort', 'sortid', 'enabled = 1', null, null, 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('station', '', null, 'station', 'stn_desc', '', '', null, 'select station, stn_desc, ip     from vxi_sys..station_view     where enabled = 1    union     select ''0'',''none'', ''0''   order by 3', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('stationIP', 'vxi_sys..station', null, 'station', 'ExtIP', 'station', 'enabled=1', null, '', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('stngrp', 'vxi_sys..groups', null, 'groupid', 'groupname', 'groupname', 'enabled = 1 and grouptype = 5', null, 'select groupid, groupname from vxi_sys..groups where grouptype = 5 and enabled = 1 order by groupname', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('storetype', 'vxi_rec..storetype', '', 'storetype', 'typename', 'storetype desc', '', null, '', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('TaskDev', 'vxi_sys..devtype', null, 'devtype', 'typename', 'devtype', 'devtype not in (6,7)', null, null, 0, 1, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('taskid', 'vxi_rec..task', '', 'taskid', 'taskname', 'taskid', 'enabled=1', null, '', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('trunk', 'vxi_sys..trunk', null, 'trunkid', 'trunkid', 'trunkid', 'enabled = 1', null, '', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('trunkgroup', '', null, 'GroupId', 'GroupName', '', '', null, 'select groupid, groupname from vxi_sys..trunkgroup m where enabled = 1  union select ''0'','''' order by 1', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('voicetype', '', null, 'VoiceType', 'TypeName', '', '', null, 'select voicetype, typename from vxi_sys..voicetype where enabled = 1  union select ''0'','''' order by 1  ', 0, 0, 1);
INSERT INTO vxi_def..Dictionary([DicName], [KeyTable], [SortField], [KeyField], [ValueField], [OrderField], [Filters], [Aliases], [SqlText], [PrivFlag], [Acked], [Enabled])  VALUES('wordid', 'vxi_rec.asr.words', null, 'wordid', 'decription', 'wordid', 'enabled = 1', null, null, 0, 0, 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   District'
Delete from vxi_def..District; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   Emails'
Delete from vxi_def..Emails; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   ExtUsers'
Delete from vxi_def..ExtUsers; 
INSERT INTO vxi_def..ExtUsers([ExtId], [ExtTable], [ExtPrefix], [ExtName], [ExtPass], [ExtRole], [ExtTitle], [ExtInfo], [Enabled])  VALUES(1, 'vxi_sys..subuser', 'sur', 'SubUser', 'Password', 'manager', '{zh:项目登录, en:Project Login}', '', 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   Favorite'
Delete from vxi_def..Favorite; 
INSERT INTO vxi_def..Favorite([UserId], [FavorId], [Title], [URL], [AddTime], [VisitTime], [SortId], [ModId], [Method], [FlowID], [NodeId], [Action], [Params], [Note], [Enabled], [actflag])  VALUES('admin', 1, '词库管理', 'WebTools?mod=rec.package&method=searchact&_json=yes&json=yes', '2011-08-11 13:50:44', '2011-08-11 13:51:06', 0, 'rec.package', 'searchact', 0, 0, '', 'limit=25&pagesize=50&start=0&page=1&json=yes&iside=true&preload=0&mod=rec.package&_json=yes&_trans=yes&method=searchact&language=zh', '', 1, null);
    end;
  
    If @Error=0 begin 
print 'Table Name:   Fields'
Delete from vxi_def..Fields; 
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aban_n', 0, null, 0, 0, '{zh:放弃呼叫数, en:Abandon Calls}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aban_t', 0, null, 0, 0, '{zh:放弃呼叫时长, en:Abandon Time}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'abanagent', 0, null, 0, 0, '{en:Aban Agent;zh:队列放弃数}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'Abandons', 0, null, 0, 0, '{zh:放弃数量, en: Abandon Calls}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'abanless', 0, null, 0, 0, '{en:Aban Less;zh:时限内放弃}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'abanmore', 0, null, 0, 0, '{en:Aban More;zh:时限外放弃}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'abanrate', 0, null, 0, 0, '{en:Aban Rate;zh:放弃率}', 'width:48', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'abanskill', 0, null, 0, 0, '{en:Aban Skill;zh:队列放弃数}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'acked', 0, '', 0, 0, '{en:Ack;zh:确认标志}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'actflag', 0, null, 0, 0, '{en:Act Flag;zh:流程}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'actid', 0, '', 0, 0, '{zh:动作代码;en:Action ID}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'action', 0, null, 0, 0, '{en:Action;zh:动作}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'active', 0, null, 0, 0, '{zh:活动事件, en:Active Event}', 'width:200', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'actkey', 0, '', 0, 0, '{zh:关键字段; en:Action Key}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'actname', 0, '', 0, 0, '{zh:动作名称; en:Action Name}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'actpage', 0, '', 0, 0, '{zh:默认页面; en:Action Page}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'actsp', 0, '', 0, 0, '{zh:存储过程; en:Action SP}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'actsql', 0, '', 0, 0, '{zh:SQL语句; en:Action SQL}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'acttab', 0, '', 0, 0, '{zh:动作表名; en:Action Tab}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'acttitle', 0, '', 0, 0, '{zh:动作标题; en:Action Title}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'acttype', 0, '', 0, 0, '{zh:动作类型; en:Action Type}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'acw', 0, '', 0, 0, '{en:Acw;zh:话后工作次数}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'acw_n', 0, '', 0, 0, '{zh:话后人数, en:ACW staffs}', 'width:80', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'acw_rate', 0, null, 0, 0, '{zh:话后时长率; en:ACW Time Rate}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'acw_t', 0, null, 0, 0, '{zh:话后时长, en:ACW Time Length}', 'renderer:wtTimeSec, width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'acwtime', 0, '', 0, 0, '{en:Acw Time;zh:话后工作时长}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'addtime', 0, null, 0, 0, '{en:Add Time;zh:添加时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'agent', 0, '', 0, 0, '{en:Agent;zh:座席}', 'renderer:wtDict,width:100', '{zh:座席工号,en:Agent Id}', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'agentlist', 0, null, 0, 0, '{en:Agent List,zh:坐席列表}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'agentname', 0, '', 0, 0, '{en:Agent Name;zh:座席名称}', 'width:64', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'agents', 0, '', 0, 0, '{en:Agents;zh:坐席数}', 'width:48', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'agents_fit', 0, null, 0, 0, '{zh:坐席人数拟合度, en:Agents Fitting}', 'width:100', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'agentstatus', 0, null, 0, 0, '{en:Agent Status; zh:坐席状态}', 'renderer:wtDict,width:60', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aht', 0, '', 0, 0, '{en:AHT(Sec.); zh:平均处理时长(s)}', 'width:100', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt00', 0, null, 0, 0, '0:00', 'width:30', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt01', 0, null, 0, 0, '1:00', 'width:30', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt02', 0, null, 0, 0, '2:00', 'width:30', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt03', 0, null, 0, 0, '3:00', 'width:30', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt04', 0, null, 0, 0, '4:00', 'width:30', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt05', 0, null, 0, 0, '5:00', 'width:30', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt06', 0, null, 0, 0, '6:00', 'width:30', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt07', 0, null, 0, 0, '7:00', 'width:30', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt08', 0, null, 0, 0, '8:00', 'width:30', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt09', 0, null, 0, 0, '9:00', 'width:30', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt10', 0, null, 0, 0, '10:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt11', 0, null, 0, 0, '11:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt12', 0, null, 0, 0, '12:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt13', 0, null, 0, 0, '13:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt14', 0, null, 0, 0, '14:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt15', 0, null, 0, 0, '15:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt16', 0, null, 0, 0, '16:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt17', 0, null, 0, 0, '17:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt18', 0, null, 0, 0, '18:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt19', 0, null, 0, 0, '19:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt20', 0, null, 0, 0, '20:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt21', 0, null, 0, 0, '21:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt22', 0, null, 0, 0, '22:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt23', 0, null, 0, 0, '23:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt25', 0, null, 0, 0, '25:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt30', 0, null, 0, 0, '30:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt40', 0, null, 0, 0, '40:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt50', 0, null, 0, 0, '50:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amt60', 0, null, 0, 0, '60:00', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'amtmore', 0, null, 0, 0, '{zh: >60, en:Amt More}', 'width:35', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ans_n', 0, null, 0, 0, '{zh:总应答数, en:Answer Calls}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ansless', 0, null, 0, 0, '{en:Ans Less;zh:及时应答数}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ansless_n', 0, null, 0, 0, '{zh:时限内应答数, en:Answer Less}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ansmore', 0, null, 0, 0, '{en:Ans More;zh:超时应答数}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ansmore_n', 0, null, 0, 0, '{zh:时限外应答数, en:Answer More}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ansRate', 0, null, 0, 0, '{zh:应答率; en:Answer Rate}', 'width:48', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'answer', 0, null, 0, 0, '{en:Answered;zh:应答号码}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'Answers', 0, null, 0, 0, '{zh:应答数量, en:Answer Calls}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'applied', 0, null, 0, 0, '{zh:应用;en:Applied}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'autobackup', 0, '', 0, 0, '{en:Auto Backup;zh:自动备份}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux_n', 0, null, 0, 0, '{zh:辅助原因人数, en:AUX agents}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux_rate', 0, null, 0, 0, '{zh:辅助时长率, en:Aux Time Rate}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux_t', 0, null, 0, 0, '{zh:辅助原因时长, en:AUX Time}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux00_n', 0, null, 0, 0, '{zh:辅助原因0人数, en:AUX0 agents}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux00_rate', 0, null, 0, 0, '{zh:辅助原因0人数比率, en:Aux Rate}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux00_t', 0, null, 0, 0, '{zh:辅助原因0时长, en:Aux0 Time}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux01_n', 0, null, 0, 0, '{zh:辅助原因1人数, en:AUX0 agents}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux01_rate', 0, null, 0, 0, '{zh:辅助原因1人数比率, en:Aux Rate}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux01_t', 0, null, 0, 0, '{zh:辅助原因1时长, en:Aux0 Time}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux02_n', 0, null, 0, 0, '{zh:辅助原因2人数, en:AUX0 agents}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux02_rate', 0, null, 0, 0, '{zh:辅助原因2人数比率, en:Aux Rate}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux02_t', 0, null, 0, 0, '{zh:辅助原因2时长, en:Aux0 Time}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux03_n', 0, null, 0, 0, '{zh:辅助原因3人数, en:AUX0 agents}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux03_rate', 0, null, 0, 0, '{zh:辅助原因3人数比率, en:Aux Rate}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux03_t', 0, null, 0, 0, '{zh:辅助原因3时长, en:Aux0 Time}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux04_n', 0, null, 0, 0, '{zh:辅助原因4人数, en:AUX0 agents}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux04_rate', 0, null, 0, 0, '{zh:辅助原因4人数比率, en:Aux Rate}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux04_t', 0, null, 0, 0, '{zh:辅助原因4时长, en:Aux0 Time}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux05_n', 0, null, 0, 0, '{zh:辅助原因5人数, en:AUX0 agents}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux05_rate', 0, null, 0, 0, '{zh:辅助原因5人数比率, en:Aux Rate}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux05_t', 0, null, 0, 0, '{zh:辅助原因5时长, en:Aux0 Time}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux06_n', 0, null, 0, 0, '{zh:辅助原因6人数, en:AUX0 agents}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux06_rate', 0, null, 0, 0, '{zh:辅助原因6人数比率, en:Aux Rate}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux06_t', 0, null, 0, 0, '{zh:辅助原因6时长, en:Aux0 Time}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux07_n', 0, null, 0, 0, '{zh:辅助原因7人数, en:AUX0 agents}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux07_rate', 0, null, 0, 0, '{zh:辅助原因7人数比率, en:Aux Rate}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux07_t', 0, null, 0, 0, '{zh:辅助原因7时长, en:Aux0 Time}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux08_n', 0, null, 0, 0, '{zh:辅助原因8人数, en:AUX0 agents}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux08_rate', 0, null, 0, 0, '{zh:辅助原因8人数比率, en:Aux Rate}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux08_t', 0, null, 0, 0, '{zh:辅助原因8时长, en:Aux0 Time}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux09_n', 0, null, 0, 0, '{zh:辅助原因9人数, en:AUX0 agents}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux09_rate', 0, null, 0, 0, '{zh:辅助原因9人数比率, en:Aux Rate}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'aux09_t', 0, null, 0, 0, '{zh:辅助原因9时长, en:Aux0 Time}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'availrate', 0, null, 0, 0, '{en:Avail Rate;zh:可用率}', 'width:48', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'availtime', 0, '', 0, 0, '{en:Avail Time;zh:总可用时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avgaban_t', 0, null, 0, 0, '{zh:平均放弃时长,en:Avg Abandon Time}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avgacdtime', 0, '', 0, 0, '{zh:技能组平均时长;en:Avg Acd Time}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avgacw_t', 0, null, 0, 0, '{en:Avg AcwTime;zh:平均话后时长}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avgacwtime', 0, '', 0, 0, '{en:Avg AcwTime;zh:平均话后处理时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avgagentans', 0, null, 0, 0, '{zh:坐席平均应答数, en:Avg Agent Ans}', 'width:100', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avgans_n', 0, null, 0, 0, '{zh:平均应答人数;en:Avg Ans Agents}', 'width:120', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avgans_t', 0, null, 0, 0, '{zh:技能平均应答时长;en:Avg Ans Time}', 'renderer:wtTimeSec,width:100', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avganstime', 0, '', 0, 0, '{zh:技能组平均应答速度;en:Avg Ans Time}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avghandle_t', 0, null, 0, 0, '{en:Avg HandleTime;zh:平均处理时间}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avghandletime', 0, '', 0, 0, '{en:Avg HandleTime;zh:平均处理时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avghold_t', 0, null, 0, 0, '{en:Avg HoldTime;zh:平均保持时间}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avgholdtime', 0, '', 0, 0, '{en:Avg HoldTime;zh:平均保持时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avgring_t', 0, null, 0, 0, '{en:Avg RingTime;zh:平均振铃时间}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avgringtime', 0, '', 0, 0, '{en:Avg RingTime;zh:平均振铃时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avgtalk_t', 0, null, 0, 0, '{en:Avg TalkTime;zh:平均通话时长}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avgtalktime', 0, '', 0, 0, '{en:Avg TalkTime;zh:平均通话时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'avgwait_t', 0, null, 0, 0, '{zh:平均等待时长,en:Avg Wait Time}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'backupdays', 0, '', 0, 0, '{en:Backup Days;zh:备份天数}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'backuptime', 0, '', 0, 0, '{en:Backup Time;zh:备份时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'begdate', 0, '', 0, 0, '{en:Start Date; zh:开始日期}', 'renderer:wtIntDate, width:80', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'begtime', 0, '', 0, 0, '{en:Start Time; zh:开始时间}', 'renderer:wtIntTime, width:120', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'bestb', 0, null, 0, 0, '{zh:接听否, en:Answer Sign}', 'width:48', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'callaban', 0, null, 0, 0, '{en:Call Aban;zh:放弃呼叫数}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'callans', 0, null, 0, 0, '{en:Call Ans;zh:总应答数}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'callavgtm', 0, '', 0, 0, '{en:Call Average Time;zh:呼叫平均时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'callconf', 0, null, 0, 0, '{en:Call Conf;zh:会议呼叫数}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'called', 0, null, 0, 0, '{en:Called No.;zh:被叫号码}', 'width:100', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'callid', 0, '', 0, 0, '{en:Call ID;zh:呼叫代码}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'calling', 0, null, 0, 0, '{en:Calling No.;zh:主叫号码}', 'width:100', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'callnum', 0, '', 0, 0, '{en:Call Volume;zh:呼叫量}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'calloffer', 0, null, 0, 0, '{en:Call Offer;zh:总呼叫数}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'calltm', 0, '', 0, 0, '{en:Call Duration;zh:呼叫时长}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'calltrans', 0, null, 0, 0, '{en:Call Trans;zh:转接呼叫数}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'calltransrate', 0, null, 0, 0, '{en:Call TransRate;zh:转接率}', 'width:48', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'calltrunk', 0, '', 0, 0, '{zh:中继呼叫总数;en:Call Trunk}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'calltype', 0, null, 0, 0, '{en:Call Type;zh:呼叫类型}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'callvol', 0, null, 0, 0, '{en:Call Vol, zh:话务量}', 'width:46', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'callvol_fit', 0, null, 0, 0, '{zh:呼叫量拟合度, en:CallVol Fitting}', 'width:100', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'cause', 0, null, 0, 0, '{zh:原因, en:Cause}', 'width:50', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'channel', 0, '', 0, 0, '{en:Channel ID;zh:通道代码}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'chtype', 0, null, 0, 0, '{zh:通道类型,en:Channel Type}', 'renderer:wtDict,width:90', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'cols', 0, '', 0, 0, '列数', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'conf_n', 0, null, 0, 0, '{en:Call Conf;zh:会议呼叫数}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'context', 0, '', 0, 0, '{en:Corba Context;zh:Corba环境}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ctrlloc', 0, '', 0, 0, '{zh:控制位;en:Ctrl}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'currcalls', 0, null, 0, 0, '{zh:当前呼叫量, en:Currenty Calls}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'custom', 0, '', 0, 0, '{en:Custom No;zh:客户号码}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'datatype', 0, null, 0, 0, '{zh:数据类型, en:Data Type}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'datawin', 0, '', 0, 0, '数据集', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'date_group', 0, '', 0, 0, '{en:Group Level;zh:分组类别}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'dateend', 0, '', 0, 0, '{en:End Date;zh:结束日期}', 'renderer:wtIntDate, width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'datestart', 0, '', 0, 0, '{en:Start Date;zh:开始日期}', 'renderer:wtIntDate, width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'dbtype', 0, null, 0, 0, '{zh:数据库类型; en:Db Type}', 'width:90', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'desc', 0, null, 0, 0, '{zh:描述, en:Depict}', 'width:200', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'destfolder', 0, '', 0, 0, '{en:Dest Folder;zh:目的文件夹}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'detail', 0, '', 0, 0, '{zh:详细描述;en:Detail}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'devflag', 0, '', 0, 0, '{en:devices Status; zh:设备状态}', 'renderer:wtDict,width:60', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'device', 0, '', 0, 0, '{en:Extension; zh:分机}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'devname', 0, '', 0, 0, '{en:Device Name;zh:设备名称}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'devtype', 0, '', 0, 0, '{en:Device Type;zh:设备类型}', 'width:100', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'dicname', 0, '', 0, 0, '{zh:字典名称;en:Dictionary Name}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'difficulty', 0, '', 0, 0, '{zh:难度;en:Difficulty}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'drive', 0, '', 0, 0, '{en:Drive;zh:盘符}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'dwsql', 0, '', 0, 0, '查询语句', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'dwtitle', 0, '', 0, 0, '标题', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'dwtype', 0, '', 0, 0, '查询类型', 'width:100', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'Enabled', 0, null, 0, 0, '{en:Status;zh:状态}', 'renderer:wtDict,width:74', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'enddate', 0, '', 0, 0, '{zh:结束日期; en:End Date}', 'renderer:wtIntDate, width:80', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'endtime', 0, '', 0, 0, '{en:End Time;zh:结束时间}', 'width:120,renderer:wtIntTime', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'exittype', 0, '', 0, 0, '{en:Exit Type;zh:结束类型}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'extdavgtm', 0, '', 0, 0, '{zh:转接挂断平均时长;en:Transferred Handup Average Time}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'extdnum', 0, '', 0, 0, '{zh:转接挂断数量;en:Transferred Handup Num}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'extdtm', 0, '', 0, 0, '{zh:转接挂断时长;en:Transferred Handup Time Length}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'extension', 0, '', 0, 0, '{en:Extension;zh:分机}', 'width:48', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'extensions', 0, null, 0, 0, '{en:Extensions;zh:分机}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'extiavgtm', 0, '', 0, 0, '{zh:IVR挂断平均时长;en:IVR Handup Average Time}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'extinfo', 0, null, 0, 0, '{zh:扩展参数,en:Ext Sort}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'extinum', 0, '', 0, 0, '{zh:IVR挂断数;en:IVR Handup Num}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'extip', 0, '', 0, 0, '{en:Ext. IP Address;zh:扩展IP地址}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'extitm', 0, '', 0, 0, '{zh:IVR挂断时长;en:IVR Handup Time Length}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'extlist', 0, null, 0, 0, '{en:Extension List,zh:分机列表}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'extuavgtm', 0, '', 0, 0, '{zh:用户挂断平均时长;en:User Handup Average Time}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'extunum', 0, '', 0, 0, '{en:Call Handup by User;zh:用户呼叫挂断数}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'extutm', 0, '', 0, 0, '{zh:用户挂断时长;en:User Handup Time Length}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'favorid', 0, '', 0, 0, '{en:Favorite ID;zh:收藏代码}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'fields', 0, '', 0, 0, '{zh:字段定义; en:Fields}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'filters', 0, '', 0, 0, '{zh:条件表达式;en: Filter}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'finished', 0, '', 0, 0, '{zh:标志; en:Finished}', 'renderer:wtFinished,width:60', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'firstlogin', 0, '', 0, 0, '{en:First Login;zh:最早登录时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'firstlogintime', 0, '', 0, 0, '{zh:首次登录时间, en:First Login Time}', '', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'flagloc', 0, '', 0, 0, '{zh:控制位置; en:Flag Loc}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'flagtime', 0, null, 0, 0, '{zh:更新时间;en:Trig Time}', 'width:120', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'flowflag', 0, null, 0, 0, '{zh:流程控制字;en:FlowFlag}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'flowicon', 0, null, 0, 0, '{zh:流程图标;en:Flow Icon}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'flowid', 0, '', 0, 0, '{en:Flow ID;zh:流程编号}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'flowname', 0, '', 0, 0, '{en:Flow Name;zh:流程名称}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'flowtab', 0, null, 0, 0, '{zh:流程控制表;en:FlowTab}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'flowtitle', 0, null, 0, 0, '{zh:流程标题;en:FlowTitle}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'folder', 0, '', 0, 0, '{en:Folder;zh:文件夹}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ftpid', 0, '', 0, 0, '{en:Store;zh:存储服务器}', 'width:100', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'groupid', 0, '', 0, 0, '{en:Group ID;zh:分组代码}', 'width:80', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'grouplist', 0, null, 0, 0, '{en:GroupList, zh:班组列表}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'groupname', 0, '', 0, 0, '{en:Group Name;zh:分组名称}', 'width:80', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'grouptype', 0, '', 0, 0, '{en:Group Type;zh:分组类型}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'handle_t', 0, null, 0, 0, '{zh:呼叫处理时长; en:Handle Time}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'height', 0, '', 0, 0, '{zh:高度; en:Height}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'hold_n', 0, null, 0, 0, '{zh:呼叫保持次数, en:Hold Num}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'hold_t', 0, null, 0, 0, '{zh:呼叫保持时长, en:Hold Time}', 'renderer:wtTimeSec,width:100', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'host', 0, '', 0, 0, '{en:Host;zh:主机IP}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'hour', 0, null, 0, 0, '{zh:时点, en:Hour}', 'width:90', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'htmlfile', 0, '', 0, 0, '{zh:模板文件;en:Template File}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'id', 0, '', 0, 0, '{en:id;zh:标识}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'idle_n', 0, null, 0, 0, '{zh:空闲人数, en:Idle Staffs}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'idle_rate', 0, null, 0, 0, '{zh:空闲时长率; en:Idle Time Rate}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'idle_t', 0, null, 0, 0, '{en:Idle Time;zh:空闲时长}', 'renderer:wtTimeSec,width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'idletime', 0, '', 0, 0, '{en:Idle Time;zh:空闲时长}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'inbound_n', 0, null, 0, 0, '{zh:呼入数;en:Inbound Num}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'inbound_t', 0, null, 0, 0, '{zh:呼入总时长 (秒);en:Total Inbound Length (sec)}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'inbound_tdn', 0, null, 0, 0, '{zh:呼入平均时长 (秒);en:Avg Inbound Length (sec)}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'inner_n', 0, null, 0, 0, '{zh:内部呼叫数;en:Inner Talks}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'innertalk', 0, '', 0, 0, '{zh:内部通话;en:Inner Talk}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'intalk', 0, '', 0, 0, '{zh:通话呼入;en:In Talk}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'intalk_n', 0, null, 0, 0, '{zh:呼入通话次数;en:In Talks}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ip', 0, '', 0, 0, '{en:IP Address;zh:IP地址}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'item01', 0, '', 0, 0, '{en:Item 01;zh:扩展01}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'item02', 0, '', 0, 0, '{en:Item 02;zh:扩展02}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'item03', 0, '', 0, 0, '{en:Item 03;zh:扩展03}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'items', 0, '', 0, 0, '{en:Task List;zh:任?窳斜韢', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ivrflow', 0, null, 0, 0, '{en:IVR  Flow,zh:IVR流程}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ivrid', 0, '', 0, 0, '{en:Record ID;zh:记录号}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'keepdays', 0, '', 0, 0, '{en:Keep Days;zh:保留天数}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'keyfield', 0, '', 0, 0, '主键字段', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'keyid', 0, '', 0, 0, '{zh:字典代码;en:Dictionary ID}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'keyname', 0, '', 0, 0, '{zh:字典名称;en:Dictionary Name}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'keyorder', 0, '', 0, 0, '{zh:排序字段;en:Order}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'keytable', 0, '', 0, 0, '{zh:数据表;en:Table}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'keyvalue', 0, '', 0, 0, '{zh:字典显示;en:View}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'label', 0, '', 0, 0, '{en:Label;zh:包含标签}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'labeltime', 0, null, 0, 0, '{en:Create Time, zh:创建时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'lastacw', 0, null, 0, 0, '{zh:最后话后, en:Last Acw}', 'width:120', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'lastlogin', 0, null, 0, 0, '{zh:最后登录, en:Last Login}', 'width:120', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'lastlogintime', 0, '', 0, 0, '{zh:最后登录时间,en:Last Login Time}', '', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'lastlogout', 0, null, 0, 0, '{en:Last Logout;zh:最晚登出时间}', 'width:120', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'lastlogouttime', 0, '', 0, 0, '{zh:最后登出时间, en:Last Logout Time}', '', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'lastnotready', 0, null, 0, 0, '{zh:最后置忙, en:Last Not Ready}', 'width:120', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'lastready', 0, null, 0, 0, '{zh:最后就绪, en:Last Ready}', 'width:120', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'linkfile', 0, '', 0, 0, '{zh:模板文件;en:Link File}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'linkid', 0, '', 0, 0, '{zh:链接代码;en:Link ID}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'linktime', 0, '', 0, 0, '{zh:时间;en:Time}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logid', 0, null, 0, 0, '{en:Login ID;zh:登录ID}', 'width:60', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'login', 0, null, 0, 0, '{en:Login;zh:登录次数}', 'width:48', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'login_n', 0, '', 0, 0, '{zh:登录人数, en:Login staffs}', 'width:64', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'login_t', 0, null, 0, 0, '{zh:登录时长, en:Login Time}', 'renderer:wtTimeSec, width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'loginmin', 0, null, 0, 0, '{zh:登录时长, en:Login Time}', 'renderer:wtTimeMin, width:60', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logintime', 0, null, 0, 0, '{en:Login Time;zh:登录时间}', 'width:120', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout_n', 0, '', 0, 0, '{zh:登出人数, en:Logout Number}', 'width:80', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout_t', 0, null, 0, 0, '{zh:登出时长, en:Logout Time}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout00', 0, '', 0, 0, '{en:Logout 00;zh:登出次数00}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout00time', 0, '', 0, 0, '{en:Logout00 Time;zh:登出时长00}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout01', 0, '', 0, 0, '{en:Logout 01;zh:登出次数01}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout01time', 0, '', 0, 0, '{en:Logout01 Time;zh:登出时长01}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout02', 0, '', 0, 0, '{en:Logout 02;zh:登出次数02}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout02time', 0, '', 0, 0, '{en:Logout02 Time;zh:登出时长02}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout03', 0, '', 0, 0, '{en:Logout 03;zh:登出次数03}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout03time', 0, '', 0, 0, '{en:Logout03 Time;zh:登出时长03}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout04', 0, '', 0, 0, '{en:Logout 04;zh:登出次数04}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout04time', 0, '', 0, 0, '{en:Logout04 Time;zh:登出时长04}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout05', 0, '', 0, 0, '{en:Logout 05;zh:登出次数05}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout05time', 0, '', 0, 0, '{en:Logout05 Time;zh:登出时长05}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout06', 0, '', 0, 0, '{en:Logout 06;zh:登出次数06}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout06time', 0, '', 0, 0, '{en:Logout06 Time;zh:登出时长06}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout07', 0, '', 0, 0, '{en:Logout 07;zh:登出次数07}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout07time', 0, '', 0, 0, '{en:Logout07 Time;zh:登出时长07}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout08', 0, '', 0, 0, '{en:Logout 08;zh:登出次数08}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout08time', 0, '', 0, 0, '{en:Logout08 Time;zh:登出时长08}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout09', 0, '', 0, 0, '{en:Logout 09;zh:登出次数09}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logout09time', 0, '', 0, 0, '{en:Logout09Time;zh:登出时长09}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logouttime', 0, null, 0, 0, '{zh:登出时间, en:Logout Time}', 'width:120', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logtime', 0, null, 0, 0, '{zh:登录时间, en:Login Time}', 'width:120', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'logtype', 0, null, 0, 0, '{zh:登录类型, en:Login Type}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'mac', 0, null, 0, 0, '{zh:物理地址,en:MAC}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'mapped', 0, '', 0, 0, '{en:Associated;zh:存在关联}', 'renderer:wtDict,width:90', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'master', 0, '', 0, 0, '{en:Agent;zh:座席}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'maxtm', 0, '', 0, 0, '{en:MaxCall Time;zh:最长呼叫时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'MaxWait_t', 0, null, 0, 0, '{zh:最长等待时长,en:Max Wait Length}', 'renderer:wtTimeSec,width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'method', 0, null, 0, 0, '{zh:方法;en:Method}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'mintm', 0, '', 0, 0, '{en:MinCall Time;zh:最短呼叫时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'modid', 0, '', 0, 0, '{zh:模块代码;en:Mod ID}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'modindex', 0, '', 0, 0, '{zh:排序号;en:Mod Index}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'modname', 0, '', 0, 0, '{zh:模块名称;en:Mod Name}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'monthmark', 0, '', 0, 0, '{en:Monthly Task;zh:每月任务}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'multirec', 0, '', 0, 0, '{zh:多重记录关联; en:MultiRec}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'nodeid', 0, null, 0, 0, '{zh:节点;en:Node}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'nodes', 0, null, 0, 0, '{zh:节点数量;en:Nodes}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'note', 0, '', 0, 0, '{en:Description;zh:描述}', 'width:200', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready_n', 0, '', 0, 0, '{zh:置忙人数, en:Not Ready staffs}', 'width:64', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready_t', 0, null, 0, 0, '{zh:置忙时长, en:NotReady Time}', 'renderer:wtTimeSec, width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready00', 0, '', 0, 0, '{en:Not Ready 00;zh:置忙状态次数00}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready00time', 0, '', 0, 0, '{en:NotReady 00 Time;zh:置忙状态时长00}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready01', 0, '', 0, 0, '{en:Not Ready 01;zh:置忙状态次数01}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready01time', 0, '', 0, 0, '{en:NotReady 01 Time;zh:置忙状态时长01}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready02', 0, '', 0, 0, '{en:Not Ready 02;zh:置忙状态次数02}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready02time', 0, '', 0, 0, '{en:NotReady 02 Time;zh:置忙状态时长02}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready03', 0, '', 0, 0, '{en:Not Ready 03;zh:置忙状态次数03}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready03time', 0, '', 0, 0, '{en:NotReady 03 Time;zh:置忙状态时长03}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready04', 0, '', 0, 0, '{en:Not Ready 04;zh:置忙状态次数04}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready04time', 0, '', 0, 0, '{en:NotReady 04 Time;zh:置忙状态时长04}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready05', 0, '', 0, 0, '{en:Not Ready 05;zh:置忙状态次数05}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready05time', 0, '', 0, 0, '{en:NotReady 05 Time;zh:置忙状态时长05}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready06', 0, '', 0, 0, '{en:Not Ready 06;zh:置忙状态次数06}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready06time', 0, '', 0, 0, '{en:NotReady 06 Time;zh:置忙状态时长06}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready07', 0, '', 0, 0, '{en:Not Ready 07;zh:置忙状态次数07}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready07time', 0, '', 0, 0, '{en:NotReady 07 Time;zh:置忙状态时长07}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready08', 0, '', 0, 0, '{en:Not Ready 08;zh:置忙状态次数08}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready08time', 0, '', 0, 0, '{en:NotReady 08 Time;zh:置忙状态时长08}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready09', 0, '', 0, 0, '{en:Not Ready 09;zh:置忙状态次数09}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'notready09time', 0, '', 0, 0, '{en:NotReady 09 Time;zh:置忙状态时长09}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'occupancy', 0, '', 0, 0, '{en:Occupancy;zh:占用率}', 'width:48', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'offhook_n', 0, null, 0, 0, '{zh:摘机次数, en:Off Hook Num}', 'width:60', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'onact', 0, '', 0, 0, '{zh:动作触发操作; en:On Action}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'onfalse', 0, '', 0, 0, '{zh:失败路径; en:On False}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ontrue', 0, '', 0, 0, '{zh:成功路径; en:On True}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'oper', 0, '', 0, 0, '{en:Type of operation;zh:操作类型}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'orderfield', 0, '', 0, 0, '{zh:排序字段;en:Order}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'outbound_n', 0, null, 0, 0, '{zh:呼出数;en:Outbound Num}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'outbound_t', 0, null, 0, 0, '{zh:呼出总时长 (秒);en:Total Outbound Length (sec)}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'outbound_tdn', 0, null, 0, 0, '{zh:呼出平均时长 (秒);en:Avg Outbound Length (sec)}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'outtalk', 0, '', 0, 0, '{zh:通话呼出;en:Out Talk}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'outtalk_n', 0, null, 0, 0, '{zh:外呼通话次数, en:Out Talks}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'params', 0, '', 0, 0, '{zh:参数列表; en:Params}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'password', 0, '', 0, 0, '{en:Password;zh:密码}', null, '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'percentage', 0, null, 0, 0, '{en:Percentage; zh:百分比}', 'renderer:wtBarPercent, width:280', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'period', 0, null, 0, 0, '{zh:周期特性, en:Periodicity}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'pophost', 0, '', 0, 0, '{en:Pop Host;zh:Pop主机}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'popport', 0, '', 0, 0, '{en:Pop Port;zh:Pop端口}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'popup', 0, '', 0, 0, '{zh:弹出状态; en:Popup}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'port', 0, '', 0, 0, '{en:Service Port;zh:服务端口}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'portno', 0, '', 0, 0, '{en:Device Port;zh:设备端口}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'precept', 0, '', 0, 0, '{zh:解决预案;en:Precept}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'primaryskill', 0, null, 0, 0, '{zh:主技能, en:Primary Skill}', 'format=dict:skill, width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'priority', 0, '', 0, 0, '{en:Priority;zh:优先级}', 'width:100', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'privilage', 0, '', 0, 0, '{en:Privilage;zh:权限}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'privilege', 0, '', 0, 0, '{en:Privilege;zh:权限}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'prjid', 0, '', 0, 0, '{en:Project ID;zh:项目}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'procdate', 0, '', 0, 0, '{zh:处理日期;en:Process Date}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'process', 0, '', 0, 0, '{zh:处理状态;en:Process}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'project', 0, '', 0, 0, '{en:Project Name; zh:项目名称}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'projectid', 0, '', 0, 0, '{zh:项目; en:Project}', 'width:80', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'projectname', 0, '', 0, 0, '{en:Project Name; zh:项目名称}', '', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'quality', 0, '', 0, 0, '{en:Quality;zh:声音品质}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'Queue_n', 0, null, 0, 0, '{zh:在线排队人数, en:Online Queue}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ready', 0, '', 0, 0, '{en:Ready;zh:就绪次数}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ready_n', 0, '', 0, 0, '{zh:就绪人数, en:Ready staffs}', 'width:80', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ready_t', 0, null, 0, 0, '{zh:就绪时长, en:Ready Time}', 'renderer:wtTimeSec, width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'readytime', 0, '', 0, 0, '{en:Ready Time;zh:就绪时长}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'realfolder', 0, null, 0, 0, '{zh:实际路径;en:Really Path}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'rec_n', 0, null, 0, 0, '{zh:录音数;en:Record Num}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'rec_t', 0, null, 0, 0, '{zh:录音总时长 (秒);en:Total Length (sec)}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'rec_tdn', 0, null, 0, 0, '{zh:平均时长 (秒);en:Avg Length (sec)}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'recdate', 0, '', 0, 0, '{en:Record Date; zh:记录日期}', 'renderer:wtIntDate, width:80', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'recdept', 0, null, 0, 0, '{en:Project/Dept. List,zh:部门/项目列表}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'recdt', 0, '', 0, 0, '{en:Date;zh:日期}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'receiver', 0, '', 0, 0, '{zh:接收方;en:Receiver}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'recflag', 0, '', 0, 0, '{en:Task Type;zh:任务类型}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'recgroup', 0, null, 0, 0, '{zh:团队/技能列表,en:Skill/Group List}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'recordid', 0, '', 0, 0, '{en:Record ID;zh:记录号}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'recpercent', 0, null, 0, 0, '{zh:录音率(%),en:Record Percent(%)}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'recperson', 0, null, 0, 0, '{zh:个人访问列表,en:Person List}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'recstorage', 0, null, 0, 0, '{en:Audio Storage, zh:声音存储}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'rectime', 0, null, 0, 0, '{en:Record Time; zh:记录时间}', 'renderer:wtIntTime, width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'rectype', 0, null, 0, 0, '{zh:记录类型, en:Record Type}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'regdate', 0, '', 0, 0, '{en:Reg Date; zh:注册日期}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'repdate', 0, '', 0, 0, '{en:Report Date;zh:日期}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'reqdate', 0, '', 0, 0, '{zh:日期;en:Date}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'reqid', 0, '', 0, 0, '{zh:代码;en:Req ID}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'reqtype', 0, '', 0, 0, '{zh:类型;en:Req Type}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'requirement', 0, '', 0, 0, '{zh:需求内容;en:Requirement}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'result', 0, '', 0, 0, '{en:Error Code;zh:错误代码}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'retrieveinterval', 0, '', 0, 0, '{en:Retrieve Interval(ms);zh:检测间隔(毫秒)}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'retset', 0, '', 0, 0, '{zh:字段集; en:RetSet}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'reverse', 0, '', 0, 0, '{zh:取反操作; en:Reverse}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ring_t', 0, null, 0, 0, '{zh:振铃时长, en:Ring Time}', 'renderer:wtTimeSec,width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'role', 0, '', 0, 0, '{en:Role;zh:角色}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'rolename', 0, '', 0, 0, '{en:Name;zh:角色名称}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'root', 0, null, 0, 0, '{zh:主节点; en:Root}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'rootfile', 0, null, 0, 0, '{zh:模版文件,en:Template File}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'rootsort', 0, null, 0, 0, '{zh:初始目录,en:Init Sort}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'rooturl', 0, '', 0, 0, '{zh:分类链接;en:Sort Link}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'route', 0, '', 0, 0, '{en:Route;zh:路由点}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'routeid', 0, '', 0, 0, '{en:ID;zh:路由代码}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'routename', 0, '', 0, 0, '{en:Route Name; zh:路由设备名称}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'routeto', 0, '', 0, 0, '{en: Route To;zh:路由目的地}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'rows', 0, '', 0, 0, '行数', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'schkeyname', 0, null, 0, 0, '{zh:查询对象,en:Search Object}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ScrPercent', 0, null, 0, 0, '{zh:截屏率(%), en:Video Percent(%)}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'scrstorage', 0, null, 0, 0, '{en:Video Storage, zh:图像存储}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'seconds', 0, '', 0, 0, '{en:Seconds; zh:时长}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'sender', 0, '', 0, 0, '{zh:提供方;en:Sender}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'servername', 0, '', 0, 0, '{en:Server Name;zh:邮件服务器名}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'service', 0, '', 0, 0, '{en:Service;zh:服务名称}', 'width:100', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'skill', 0, '', 0, 0, '{en:Skill;zh:技能}', 'width:100', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'skill_n', 0, null, 0, 0, '{zh:技能呼叫总数;en:Skill CallOffer}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'skillans', 0, '', 0, 0, '{zh:技能组应答数;en:Skill Ans}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'skillcall', 0, '', 0, 0, '{zh:技能组呼入数;en:Skill Call}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'SkillGroup', 0, '', 0, 0, '{zh:技能组, en:Skill Group}', 'width:100', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'skillid', 0, '', 0, 0, '{zh:技能, en:Skill ID}', 'width:80', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'skillin_n', 0, null, 0, 0, '{zh:技能组呼入量;en:Skill Num}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'skilllist', 0, null, 0, 0, '{en:Skill List,zh:技能列表}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'skillname', 0, '', 0, 0, '{en:Skill Name; zh:技能组名称}', 'width:100', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'skills', 0, '', 0, 0, '{en:Skill;zh:技能组}', 'width:80', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'skilltype', 0, null, 0, 0, '{zh:技能组类型, en:Skill Type}', 'width: 80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'smtphost', 0, '', 0, 0, '{en:Smtp Host;zh:Smtp主机}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'smtpport', 0, '', 0, 0, '{en:Smtp Port;zh:Smtp端口}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'solution', 0, '', 0, 0, '{zh:解决方案;en:Solution}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'sort', 0, '', 0, 0, '{zh:分类名称;en:Sort Name}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'sort01', 0, '', 0, 0, '{zh:一层;en: Sort01}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'sort02', 0, '', 0, 0, '{zh:二层;en: Sort02}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'sort03', 0, '', 0, 0, '{zh:三层;en: Sort03}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'sort04', 0, '', 0, 0, '{zh:四层;en: Sort04}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'sort05', 0, '', 0, 0, '{zh:五层;en: Sort05}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'sort06', 0, '', 0, 0, '{zh:六层;en: Sort06}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'sortfield', 0, '', 0, 0, '{zh:分组字段;en:Sort Field}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'sortid', 0, '', 0, 0, '{zh:分类代码;en:Sort ID}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'sqltext', 0, null, 0, 0, '{zh:SQL语句;en:SQL Text}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'startday', 0, '', 0, 0, '{en:Start Date;zh:开始日期}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'starttime', 0, '', 0, 0, '{en:Start Time;zh:开始时间}', 'width:100, renderer:wtIntTime', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'state', 0, '', 0, 0, '{en:State;zh:状态}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'station', 0, '', 0, 0, '{en:Station;zh:计算机}', 'width:150', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'status', 0, null, 0, 0, '{zh:状态, en:Status}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'stopday', 0, '', 0, 0, '{en:End Day;zh:结束日期}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'subid', 0, '', 0, 0, '{en:Item ID;zh:代码}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'subuser', 0, null, 0, 0, '{en:Project Account,zh:项目用户}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'summary', 0, '', 0, 0, '{en:Description;zh:分组描述}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'svclevel', 0, '', 0, 0, '{en:Svc Level;zh:服务水平}', 'width:60', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'svcoper', 0, null, 0, 0, '{zh:操作, en:Actions}', 'width:130', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'svctype', 0, '', 0, 0, '{en:Service Type;zh:服务类型}', 'width:80', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'switchin', 0, '', 0, 0, '{en:Access No.; zh:电话接入号}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 't_gt3600_n', 0, null, 0, 0, '{zh:大于60分钟;en: > 60minutes}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 't0_60_n', 0, null, 0, 0, '{zh:1分钟内;en:<= 1 minute}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 't1201_1800_n', 0, null, 0, 0, '{zh:20 - 30分钟;en:20 - 30 minutes}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 't121_180_n', 0, null, 0, 0, '{zh:2 - 3分钟;en:2 - 3 minutes}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 't1801_3000_n', 0, null, 0, 0, '{zh:30 - 50分钟;en:30 - 50 minutes}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 't181_300_n', 0, null, 0, 0, '{zh:3 - 5分钟;en:3 - 5 minutes}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 't3001_3600_n', 0, null, 0, 0, '{zh:50 - 60分钟;en:50 - 60 minutes}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 't301_480_n', 0, null, 0, 0, '{zh:5 - 8分钟;en:5 - 8 minutes}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 't481_600_n', 0, null, 0, 0, '{zh:8 - 10分钟;en:8 - 10 minutes}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 't601_1200_n', 0, null, 0, 0, '{zh:10 - 20分钟;en:10 - 20 minutes}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 't61_120_n', 0, null, 0, 0, '{zh:1 - 2分钟;en:1 - 2 minutes}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'tabkey', 0, '', 0, 0, '{zh:主表主键;en:Table Key}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'tabname', 0, '', 0, 0, '{zh:模块主表;en:Table Name}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'Talk_n', 0, null, 0, 0, '{zh:通话人数, en:Talk Staffs}', 'width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'talk_rate', 0, null, 0, 0, '{zh:通话时长率; en:Talk Time Rate}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'talk_t', 0, null, 0, 0, '{zh:通话时长, en:Talk Time}', 'renderer:wtTimeSec, width:64', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'talkless10', 0, '', 0, 0, '{zh:外拨通话10秒内;en:Talk Less10}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'talkless10_n', 0, null, 0, 0, '{zh:外拨通话10秒内数量;en:Talk Less10}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'talkless20', 0, '', 0, 0, '{zh:外拨通话20秒内;en:Talk Less20}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'talkless20_n', 0, null, 0, 0, '{zh:外拨通话20秒内数量;en:Talk Less20}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'talkmore20', 0, '', 0, 0, '{zh:外拨通话大于20秒;en:Talk More20}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'talkmore20_n', 0, null, 0, 0, '{zh:外拨通话大于20秒数量;en:Talk More20}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'talktime', 0, '', 0, 0, '{en:Talk Time;zh:通话时长}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'taskid', 0, '', 0, 0, '{en:Task ID;zh:任务代码}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'tasklist', 0, null, 0, 0, '{en:Task List,zh:任务列表}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'taskname', 0, '', 0, 0, '{en:Task Name;zh:任务名称}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'tasktype', 0, '', 0, 0, '{en:Time Type;zh:时间类型}', '', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'timeend', 0, '', 0, 0, '{en:End Time;zh:结束时间}', 'renderer:wtIntTime, width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'timelen', 0, '', 0, 0, '{en:Route Time Lengthen;zh:时长}', 'width:70', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'timesec', 0, null, 0, 0, '{zh:时长, en:Time Len}', 'renderer:wtTimeSec, width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'timespan', 0, null, 0, 0, '{zh:时间间隔(分); en:Time Span(min)}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'timestart', 0, '', 0, 0, '{en:Start Time;zh:开始时间}', 'renderer:wtIntTime, width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'title', 0, '', 0, 0, '{en:Title;zh:标题}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'topic', 0, '', 0, 0, '{zh:链接标题;en:Title}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'total_n', 0, '', 0, 0, '{zh:总数, en:Total}', 'width:60', '', 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'total_t', 0, null, 0, 0, '{en:Total TalkTime;zh:总通话时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'totalcall', 0, '', 0, 0, '{zh:呼叫总数;en:Total Call}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'totaltalktime', 0, '', 0, 0, '{en:Total TalkTime;zh:总通话时间}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trans_n', 0, null, 0, 0, '{en:Call Trans;zh:转接呼叫数}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunk', 0, '', 0, 0, '{en:Trunk;zh:中继号}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunk_n', 0, null, 0, 0, '{zh:中继呼叫总数;en:Call Trunk}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkgroup', 0, '', 0, 0, '{en:Trunk Group; zh:中继组}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkid', 0, '', 0, 0, '{en:Trunk ID; zh:中继代码}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkin', 0, '', 0, 0, '{en:Trunk In;zh:中继呼入数}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkin_n', 0, null, 0, 0, '{zh:呼入量;en:Trunk Num}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkin_t', 0, null, 0, 0, '{zh:中继呼入时长, en:Trunk In Time Length}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkinans', 0, '', 0, 0, '{en:Trunk InAns;zh:中继呼入应答数}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkinans_ivr_n', 0, null, 0, 0, '{zh:呼叫应答量;en:Trunk Answer Num}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkinans_n', 0, null, 0, 0, '{en:Trunk In Ans;zh:中继呼入应答数}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkinans_skill_n', 0, null, 0, 0, '{zh:技能组呼叫应大量;en:Trunk Answer Skill Num}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkinans_t', 0, null, 0, 0, '{zh:中继呼入应答时长, en:Trunk In Answer Time}', 'width:100', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunknum', 0, '', 0, 0, '{en:Trunk No.; zh:中继号}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkout', 0, '', 0, 0, '{zh:中继呼出数量;en:Trunk Out}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkout_n', 0, null, 0, 0, '{zh:中继呼出数量;en:Trunk Out}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkout_t', 0, null, 0, 0, '{zh:中继呼出时长;en:Trunk Out Time Length}', 'width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkoutans', 0, '', 0, 0, '{zh:中继呼出应答;en:Trunk Out Ans}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkoutans_n', 0, null, 0, 0, '{zh:中继呼出应答数量;en:Trunk Out Ans}', 'width:100', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'trunkoutans_t', 0, null, 0, 0, '{zh:中继呼出应答时长;en:Trunk Out Ans Time}', 'width:100', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'type', 0, '', 0, 0, '{en:Call Type;zh:呼叫类型}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'typename', 0, '', 0, 0, '{en:Group Type;zh:分组类型}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'ucdid', 0, null, 0, 0, '{en:UCDID;zh:统一联络代码}', 'width:92', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'unregdate', 0, '', 0, 0, '{en:Unreg Date;zh:注消日期}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'url', 0, '', 0, 0, '{en:URL;zh:链接}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'userid', 0, '', 0, 0, '{en:Email Accounts;zh:Email帐号}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'username', 0, '', 0, 0, '{en:Username;zh:用户名}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'validtime', 0, '', 0, 0, '{zh:有效日期;en:Valid Time}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'valuefield', 0, '', 0, 0, '{zh:字典显示;en:View}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'visittime', 0, null, 0, 0, '{zh:浏览时间;en:Visit Time}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'voicetype', 0, '', 0, 0, '{en:Voice Type; zh:语音文件类型}', 'width:120', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'Wait_n', 0, '', 0, 0, '{zh:等待量,en:Wait calls}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'wait_t', 0, null, 0, 0, '{zh:客户等待时长, en:Wait length}', 'renderer:wtTimeSec, width:80', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'waitless', 0, null, 0, 0, '{zh:客户时限等待, en:DurationAnswers}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'waitoncalls', 0, null, 0, 0, '{zh:在线排队呼叫量, en:Wait On Calls}', 'width:90', null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'weekmark', 0, '', 0, 0, '{en:Weekly Task;zh:每周任务}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'width', 0, '', 0, 0, '{zh:宽度; en:Width}', null, null, 1);
INSERT INTO vxi_def..Fields([TabName], [Field], [FieldIndex], [FieldType], [FieldLen], [PrimaryKey], [DispStr], [Format], [Summary], [Enabled])  VALUES('*', 'writer', 0, null, 0, 0, '{en:Creator;zh:新建者}', null, null, 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   Flow'
Delete from vxi_def..Flow; 
INSERT INTO vxi_def..Flow([FlowId], [FlowName], [FlowTitle], [SortId], [CtrlLoc], [FlowTab], [FlowKey], [Fields], [FieldX], [FlowFlag], [Root], [FlowIcon], [FlowPage], [InitParams], [InitSQL], [InitPage], [FlowSel], [Nodes], [Summary], [Acked], [Enabled])  VALUES(80, '{zh:原始记录报表, en:Original Records}', '{zh:原始记录报表, en:Original Records}', 70000000, 65, null, null, null, null, null, 0, null, null, '', '', '', '', 5, null, null, 1);
INSERT INTO vxi_def..Flow([FlowId], [FlowName], [FlowTitle], [SortId], [CtrlLoc], [FlowTab], [FlowKey], [Fields], [FieldX], [FlowFlag], [Root], [FlowIcon], [FlowPage], [InitParams], [InitSQL], [InitPage], [FlowSel], [Nodes], [Summary], [Acked], [Enabled])  VALUES(81, '{zh:呼叫统计报表, en:Call Statistics}', '{zh:呼叫统计报表, en:Call Statistics}', 70000000, 65, null, null, null, null, null, 0, null, null, '', null, '', '', 6, null, null, 1);
INSERT INTO vxi_def..Flow([FlowId], [FlowName], [FlowTitle], [SortId], [CtrlLoc], [FlowTab], [FlowKey], [Fields], [FieldX], [FlowFlag], [Root], [FlowIcon], [FlowPage], [InitParams], [InitSQL], [InitPage], [FlowSel], [Nodes], [Summary], [Acked], [Enabled])  VALUES(82, '{zh:坐席统计报表, en:Agent Statistics}', '{zh:坐席统计报表, en:Agent Statistics}', 70000000, 65, null, null, null, null, null, 0, null, null, '', null, '', '', 8, null, null, 1);
INSERT INTO vxi_def..Flow([FlowId], [FlowName], [FlowTitle], [SortId], [CtrlLoc], [FlowTab], [FlowKey], [Fields], [FieldX], [FlowFlag], [Root], [FlowIcon], [FlowPage], [InitParams], [InitSQL], [InitPage], [FlowSel], [Nodes], [Summary], [Acked], [Enabled])  VALUES(83, '{zh:分机统计报表, en:Extension Statistics}', '{zh:分机统计报表, en:Extension Statistics}', 70000000, 65, null, null, null, null, null, 0, null, null, '', null, '', '', 3, null, null, 1);
INSERT INTO vxi_def..Flow([FlowId], [FlowName], [FlowTitle], [SortId], [CtrlLoc], [FlowTab], [FlowKey], [Fields], [FieldX], [FlowFlag], [Root], [FlowIcon], [FlowPage], [InitParams], [InitSQL], [InitPage], [FlowSel], [Nodes], [Summary], [Acked], [Enabled])  VALUES(84, '{zh:采样统计报表, en:Sample Statistics}', '{zh:采样统计报表, en:Sample Statistics}', 70000000, 65, null, null, null, null, null, 1, null, null, '', null, '', '', 5, null, null, 1);
INSERT INTO vxi_def..Flow([FlowId], [FlowName], [FlowTitle], [SortId], [CtrlLoc], [FlowTab], [FlowKey], [Fields], [FieldX], [FlowFlag], [Root], [FlowIcon], [FlowPage], [InitParams], [InitSQL], [InitPage], [FlowSel], [Nodes], [Summary], [Acked], [Enabled])  VALUES(86, '{zh:技术指标分析, en:Performance Analysis}', '{zh:技术指标分析, en:Performance Analysis}', 70000000, 65, null, null, null, null, null, 0, null, null, '', null, '', '', 15, null, null, 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   Holidays'
Delete from vxi_def..Holidays; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   HotFields'
Delete from vxi_def..HotFields; 
INSERT INTO vxi_def..HotFields([HotKey], [HotModule], [HotURL], [Enabled])  VALUES('recordid', 'rec.log', null, 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   Links'
Delete from vxi_def..Links; 
INSERT INTO vxi_def..Links([LinkId], [SortId], [Topic], [LinkTime], [ValidTime], [LinkFile], [WWW], [Summary], [Acked], [Enabled])  VALUES(1, 20200000, '{zh:IVR通道定义, en:IVR Channel Setting}', '2005-01-01 00:00:00', '2036-12-31 00:00:00', '', 'WebTools?method=search&mod=ivr.ch', null, 0, 0);
INSERT INTO vxi_def..Links([LinkId], [SortId], [Topic], [LinkTime], [ValidTime], [LinkFile], [WWW], [Summary], [Acked], [Enabled])  VALUES(2, 20200000, '{zh:VRS录音通道定义, en:VRS Channel Setting}', '2005-01-01 00:00:00', '2036-12-31 00:00:00', '', 'WebTools?method=search&mod=rec.ch', null, null, 0);
    end;
  
    If @Error=0 begin 
print 'Table Name:   Modules'
Delete from vxi_def..Modules; 
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('action', '{zh:模块动作定义, en:Action Defination}', 100, '0', 10100000, 2, 15, 15, 15, 16777215, 'action', 'actid', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', 'calendar.jsp', 'schcombox.jsp', 'action.jsp', 'action.jsp', 'action.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', '', null, '', '', '', '', '', '', 'syn=action  syn=dict', 'syn=action  syn=dict', 'syn=action  syn=dict', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, null, null, null, null, 'actid=动作代码,  ActName=动作名称,   ActTitle=动作标题,   ModId=模块代码,   SortId=分类代码,  Reverse=Reverse,   FlagLoc=控制位置,   ActType=动作类型,   Fields=字段定义, MultiRec=MultiRec,   ActSQL=SQL语句,   ActSP=存储过程,   OnAct=OnAct,   OnTrue=成功路径,   OnFalse=失败路径,   actid={zh:动作代码;en:Action ID},  ActName={zh:动作名称; en:Action Name},  ActTitle={zh:动作标题; en:Action Title},  ModId={zh:模块代码; en:Mod Id},  SortId={zh:分类代码;en:Sort Id},  Reverse={zh:取反操作; en:Reverse},  FlagLoc={zh:控制位置; en:Flag Loc},  ActType={zh:动作类型; en:Action Type},  Fields={zh:字段定义; en:Fields},  MultiRec={zh:多重记录关联; en:MultiRec},  ActSQL={zh:SQL语句; en:Action SQL},  ActSP={zh:存储过程; en:Action SP},  OnAct={zh:动作触发操作; en:On Action},  OnTrue={zh:成功路径; en:On True},  OnFalse={zh:失败路径; en:On False},  Popup={zh:弹出状态; en:Popup},  ActTab={zh:动作表名; en:Action Tab},  ActPage={zh:默认页面; en:Action Page},  ActKey={zh:关键字段; en:Action Key},  Params={zh:参数列表; en:Params},  Width={zh:宽度; en:Width},  Height={zh:高度; en:Height},  RetSet={zh:字段集; en:RetSet},  Enabled={zh:有效状态;en:Enabled}', '<fieldx>   <field name="actid" owner="master">    <type></type>    <title>动作代码</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>30</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey>yes</tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="actname" owner="master">    <type></type>    <title>动作名称</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>50</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="acttitle" owner="master">    <type></type>    <title>动作标题</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>100</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="modid" owner="master">    <type></type>    <title>模块代码</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>200</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="sortid" owner="master">    <type></type>    <title>分类代码</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="allready" owner="master">    <type></type>    <title>AllReady</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="partready" owner="master">    <type></type>    <title>PartReady</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="notready" owner="master">    <type></type>    <title>NotReady</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="reverse" owner="master">    <type></type>    <title>Reverse</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="flagloc" owner="master">    <type></type>    <title>控制位置</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="fieldx" owner="master">    <type></type>    <title>FieldX</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="acttype" owner="master">    <type></type>    <title>动作类型</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="fields" owner="master">    <type></type>    <title>字段定义</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>100</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="multirec" owner="master">    <type></type>    <title>MultiRec</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="actsql" owner="master">    <type></type>    <title>SQL语句</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="actsp" owner="master">    <type></type>    <title>存储过程</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="onact" owner="master">    <type></type>    <title>OnAct</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="ontrue" owner="master">    <type></type>    <title>成功路径</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="onfalse" owner="master">    <type></type>    <title>失败路径</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="popup" owner="master">    <type></type>    <title>{zh:弹出状态; en:Popup}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="acttab" owner="master">    <type></type>    <title>{zh:动作表名; en:Action Tab}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>50</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="actpage" owner="master">    <type></type>    <title>{zh:默认页面; en:Action Page}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>50</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="actkey" owner="master">    <type></type>    <title>{zh:关键字段; en:Action Key}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>50</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="params" owner="master">    <type></type>    <title>{zh:参数列表; en:Params}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>200</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="width" owner="master">    <type></type>    <title>{zh:宽度; en:Width}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="height" owner="master">    <type></type>    <title>{zh:高度; en:Height}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="retset" owner="master">    <type></type>    <title>{zh:字段集; en:RetSet}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="resetflag" owner="master">    <type></type>    <title>ResetFlag</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="enabled" owner="master">    <type></type>    <title>{zh:有效状态;en:Enabled}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>  </fieldx>  ', null, null, null, null, null, null, null, null, null, 'actid=动作代码,  SortId=分类代码,  ModId=模块代码,  FlagLoc=控制位置', 'select m.actid, m.ActName, m.ActTitle, m.SortId,  m.FlagLoc, m.ActType, m.ActTab, m.ActPage, m.ActKey, m.Width, m.Height from action m', 'select m.* from action m where m.actid = !actid', 'select m.* from action m where m.actid = !actid', null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, 1, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('agent', '{zh:座席资源设置, en:Agent Setting}', 100, '0', 20100000, 11, 7, 15, 15, -1, 'vxi_sys..agent', 'agent', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, 'ext.edit.search.jsp', '', '', 'agent.jsp', 'agent.jsp', 'agent.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'syn=dict  send=VisionCTI  send=VisionEMS  send=VisionLog  sp=vxi_ucd..sp_syn_rt_agent @agent=!agent', 'syn=dict  send=VisionCTI  send=VisionEMS  send=VisionLog  sp=vxi_ucd..sp_syn_rt_agent @agent=!agent', 'syn=dict  send=VisionCTI  send=VisionEMS  send=VisionLog  sp=vxi_ucd..sp_syn_rt_agent @agent=!agent', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', 'newact=newact', 'sortid=20100000', '', 'agent={en:Agent; zh:工号}, AgentName={en:Agent Name;zh:座席名称}, Sort={en:Sort;zh:分类}, RegDate={en:Reg Date; zh:注册日期}, UnregDate={en:Unreg Date;zh:注消日期}, State={en:State; zh:状态}, Enabled={en:Enable; zh:有效标志}', '<fieldx>   <field name="agent" owner="master">    <type></type>    <title>{en:Agent; zh:工号}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey>yes</tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="agentname" owner="master">    <type></type>    <title>{en:Agent Name;zh:座席名称}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>50</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="sortid" owner="master">    <type></type>    <title>SortId</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter>20100000</filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="regdate" owner="master">    <type></type>    <title>{en:Reg Date; zh:注册日期}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="enabled" owner="master">    <type></type>    <title>{en:Enable; zh:有效标志}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>  </fieldx>  ', null, null, null, null, '', null, null, '', null, 'agent=Agent ID, AgentName=Agent Name', 'select m.agent, m.AgentName,  m.enabled from vxi_sys..agent m left join sort t on m.sortid = t.sortid', 'select m.agent, m.AgentName, m.SortId, m.RegDate, m.Enabled from vxi_sys..agent m where m.agent = !agent', 'select m.agent, m.AgentName, m.SortId, m.Enabled from vxi_sys..agent m where m.agent = !agent', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('agent.log.rec', '{en:Agent Login records, zh:座席登录操作记录}', 100, '0', 30200000, 36, 1, 15, 15, -1, '', 'logid', 1, 0, null, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', 'agent.log.rec.jsp', '', '', 'vxi_call..sp_agent_login_rec @logid = !logid', '', '', '', '', '', '', '', '', 'vxi_call..sp_agent_login_rec', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, 'Agent Login records', '', '', '', 'logid={en:Login ID;zh:登录ID},  agent={en:Agent;zh:座席},  skills={en:Skill;zh:技能组},  device={en:Device;zh:设备号},  starttime={en:Beginning Time;zh:开始时间},  endtime={en:End Time;zh:结束时间},  timelen={en:Time Length;zh:时间长度},  oper={en:Type of operation;zh:操作类型}', null, null, null, null, null, '', '', null, '', null, 'logid=Records of, agent=Seating, skills=Group skills, device=Ext., TimeRange=time', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('audio.dev', '{en:Audio Devices Setting, zh:交换机语音设备设置}', 100, '0', 20100000, 11, 7, 15, 15, -1, 'vxi_sys..devices', 'device', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, 'ext.edit.search.jsp', '', '', 'audio.dev.jsp', 'audio.dev.jsp', 'audio.dev.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'syn=dict  send=VisionCTI  send=VisionEMS  send=VisionLog', 'syn=dict  send=VisionCTI  send=VisionEMS  send=VisionLog', 'syn=dict  send=VisionCTI  send=VisionEMS  send=VisionLog', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', 'sortid=20100000, devtype=7', '', 'device={en:Audio Device; zh:语音设备}, sort={en:Sort; zh:分类}, devname={en:Device Name; zh:设备名称}, Enabled={en:Status; zh:有效标志}', null, null, null, null, null, '', '', null, '', null, 'device=Audio Device, devname=Device Name', 'select m.device,m.devtype,  m.devname,  m.enabled from vxi_sys..devices m left join sort t on m.sortid = t.sortid', 'select m.device, m.sortid, m.devname, m.enabled from vxi_sys..devices m where m.device = !device', 'select m.device, m.devtype, m.sortid, m.devname, m.enabled from vxi_sys..devices m where m.device = !device', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('cd.stat.agent.report.day', '座席状态日统计报表', 100, '', 60300000, 35, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, '', '', 'cd.stat.agent.sch.jsp', '', '', '', '', '', '', '', '', '', '', '', '', null, 'vxi_crm..sp_chengdu_stat_agent_report', '', '', null, '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'RepDate=统计日期', null, null, null, null, null, '', 'Login_ht=3, CallInOut_ht=3, CallInOut_tdl=0%, CallInOut_ndl=0, CallInOut_tdn=0, CallIn_ht=3, CallIn_tdl=0%, CallIn_ndl=0, CallIn_tdn=0, CallOut_ht=3, CallOut_tdl=0%, CallOut_ndl=0, CallOut_tdn=0, CallInner_ht=3, Idle_t=3, Idle_tdl=0%, NotReady_ht=3, NotReady_tdl=0%, Ans_tdn=0, Ans_tdl=0%, Efficiency=3', null, '', null, 'DateSch=RepDate,PrjId=项目,Agents=座席', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('cd.stat.agent.report.month', '座席状态月统计报表', 100, '', 60300000, 35, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, '', '', 'cd.stat.agent.sch.jsp', '', '', '', '', '', '', '', '', '', '', '', '', null, 'vxi_crm..sp_chengdu_stat_agent_report', '', '', null, '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, null, null, null, null, 'RepDate=统计日期', null, null, null, null, null, null, 'Login_ht=3, CallInOut_ht=3, CallInOut_tdl=0%, CallInOut_ndl=0, CallInOut_tdn=0, CallIn_ht=3, CallIn_tdl=0%, CallIn_ndl=0, CallIn_tdn=0, CallOut_ht=3, CallOut_tdl=0%, CallOut_ndl=0, CallOut_tdn=0, CallInner_ht=3, Idle_t=3, Idle_tdl=0%, NotReady_ht=3, NotReady_tdl=0%, Ans_tdn=0, Ans_tdl=0%, Efficiency=3', null, null, null, 'MonthSch=RepDate,PrjId=项目,Agents=座席', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('cd.stat.agent.report.range', '座席状态统计报表(定制)', 100, '', 60300000, 35, 1, 15, 15, -1, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'search.grid.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_crm..sp_chengdu_stat_agent_report', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'groupid={en:groupid;zh:组},  agent={en:agent;zh:座席代码},  login_t={en:login_t;zh:登录时间},  callinout_t={en:callinout_t;zh:总通话时间},  callinout_tdl={en:callinout_tdl;zh:总通话率(%)},  callinout_n={en:callinout_n;zh:总呼叫数},  callinout_ndl={en:callinout_ndl;zh:每小时呼叫总数},  callinout_tdn={en:callinout_tdn;zh:总呼叫平均通话时间},  callin_t={en:callin_t;zh:呼入通话时间},  callin_tdl={en:callin_tdl;zh:呼入通话率(%)},  callin_n={en:callin_n;zh:呼入数},  callin_ndl={en:callin_ndl;zh:每小时呼入数},  callin_tdn={en:callin_tdn;zh:呼入平均通话时间},  callout_t={en:callout_t;zh:呼出通话时间},  callout_tdl={en:callout_tdl;zh:呼出通话率(%)},  callout_n={en:callout_n;zh:呼出数},  callout_ndl={en:callout_ndl;zh:每小时呼出叫数},  callout_tdn={en:callout_tdn;zh:呼出平均通话时间},  callinner_t={en:callinner_t;zh:内部通话时间},  callinner_n={en:callinner_n;zh:内部呼叫数},  trans_n={en:trans_n;zh:呼叫转移数},  idle_t={en:idle_t;zh:等待时间},  idle_tdl={en:idle_tdl;zh:等待时间率},  notready_t={en:notready_t;zh:未就绪时间},  notready_tdl={en:notready_tdl;zh:未就绪时间率},  ans_tdn={en:ans_tdn;zh:振铃平均时间},  ans_tdl={en:ans_tdl;zh:振铃时间率},  efficiency={en:efficiency;zh:直接工作效率}', null, '', '', '', '', '', 'login_t=time_sec,  callinout_tdn=time_sec,  notready_t=time_sec,  idle_t=time_sec,  callout_t=time_sec,  callinner_t=time_sec,  callin_t=time_sec,  callin_tdn=time_sec,  callinout_t=time_sec,  callout_tdn=time_sec,  Login_ht=3, CallInOut_ht=3, CallInOut_tdl=0%, CallInOut_ndl=0, CallIn_ht=3, CallIn_tdl=0%, CallIn_ndl=0,  CallOut_ht=3, CallOut_tdl=0%, CallOut_ndl=0, CallInner_ht=3,  Idle_tdl=0%, NotReady_ht=3, NotReady_tdl=0%, Ans_tdn=time_sec, Ans_tdl=0%, Efficiency=0%', '', '', '', 'TimeRange=Time,PrjId=项目,Agents=座席', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('config', '{zh:服务配置管理, en:Service Configuration}', 100, null, 10300000, 3, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'config.sch.jsp', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rt.monitor', '{zh:实时监听, en:Realtime Monitor}', 100, '0', 50200000, 42, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'rt.monitor.jsp', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('subuser', '{zh:项目用户设置,en:Project Account Setting}', 110, null, 10200000, 2, 7, 15, 15, -1, 'vxi_sys..subuser', 'subuser', 0, 0, null, null, null, 0, 0, null, null, null, 1000, 0, 'ext.search.jsp', null, null, 'subuser.jsp', 'subuser.jsp', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'subuser,role,projectid', 'select su.subuser, su.username, su.ProjectId, su.skilllist, su.agentlist, su.extlist, su.tasklist, su.enabled   from vxi_sys..subuser su', 'select m.*, r.rolename, r.privilege from vxi_sys..subuser m, roles r where m.role = r.role and m.subuser = !subuser', 'select m.subuser,m.username,m.password, m.role, m.projectid, m.skilllist, m.agentlist, m.extlist, m.tasklist, m.grouplist,m. enabled from vxi_sys..subuser m where m.subuser = !subuser', null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('cd.stat.agent.report.year', '座席状态年统计报表', 100, '', 60300000, 35, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, '', '', 'cd.stat.agent.sch.jsp', '', '', '', '', '', '', '', '', '', '', '', '', null, 'vxi_crm..sp_chengdu_stat_agent_report', '', '', null, '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, null, null, null, null, 'RepDate=统计日期', null, null, null, null, null, null, 'Login_ht=3, CallInOut_ht=3, CallInOut_tdl=0%, CallInOut_ndl=0, CallInOut_tdn=0, CallIn_ht=3, CallIn_tdl=0%, CallIn_ndl=0, CallIn_tdn=0, CallOut_ht=3, CallOut_tdl=0%, CallOut_ndl=0, CallOut_tdn=0, CallInner_ht=3, Idle_t=3, Idle_tdl=0%, NotReady_ht=3, NotReady_tdl=0%, Ans_tdn=0, Ans_tdl=0%, Efficiency=3', null, null, null, 'YearSch=RepDate,PrjId=项目,Agents=座席', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('cd.stat.call.report.day', '呼叫日统计报表', 100, '', 60300000, 35, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, '', '', 'cd.stat.call.sch.jsp', '', '', '', '', '', '', '', '', '', '', '', '', null, 'vxi_crm..sp_chengdu_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'RepDate=统计日期', null, null, null, null, null, '', 'SkillIn_n=0, Ans_nds=0%, AnsLess_nds=0%, Ans_tdn=0, Aban_n=0, Aban_nds=0%, AbanSkill_nda=0%, AbanAgent_nda=0%, Aban_tdn=0, CallIn_ht=3, Login_ht=3', null, '', null, 'DateSch=RepDate,PrjId=项目,Agents=座席,SkillList=技能组', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('cd.stat.call.report.month', '呼叫月统计报表', 100, '', 60300000, 35, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, '', '', 'cd.stat.call.sch.jsp', '', '', '', '', '', '', '', '', '', '', '', '', null, 'vxi_crm..sp_chengdu_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, null, null, null, null, 'RepDate=统计日期', null, null, null, null, null, null, 'SkillIn_n=0, Ans_nds=0%, AnsLess_nds=0%, Ans_tdn=0, Aban_n=0, Aban_nds=0%, AbanSkill_nda=0%, AbanAgent_nda=0%, Aban_tdn=0, CallIn_ht=3, Login_ht=3', null, null, null, 'MonthSch=RepDate,PrjId=项目,Agents=座席,SkillList=技能组', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('cd.stat.call.report.range', '呼叫统计报表_30分钟报表', 100, '', 60300000, 35, 1, 15, 15, -1, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'search.grid.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_crm..sp_chengdu_stat_call_report', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'recdt={en:recdt;zh:日期时间},  trunkin_n={en:trunkin_n;zh:交换机呼入数},  trunkout_n={en:trunkout_n;zh:交换机呼出数},  skillin_n={en:skillin_n;zh:技能组来电总数},  ans_n={en:ans_n;zh:技能组应答数},  ans_nds={en:ans_nds;zh:技能组接听成功%},  ansless_n={en:ansless_n;zh:技能组应答15秒前},  ansless_nds={en:ansless_nds;zh:技能组应答15秒前%},  ansmore_n={en:ansmore_n;zh:技能组应答15秒后},  ans_tdn={en:ans_tdn;zh:技能组应答速度},  aban_n={en:aban_n;zh:技能组放弃总数},  aban_nds={en:aban_nds;zh:技能组放弃%},  abanmore_n={en:abanmore_n;zh:技能组放弃15秒后},  abanskill_n={en:abanskill_n;zh:技能组队列内放弃数},  abanskill_nda={en:abanskill_nda;zh:技能组队列内放弃%},  abanagent_n={en:abanagent_n;zh:技能组座席放弃},  abanagent_nda={en:abanagent_nda;zh:技能组座席放弃%},  aban_tdn={en:aban_tdn;zh:技能组放弃时间},  maxans_t={en:maxans_t;zh:最长振铃时间},  callin_t={en:callin_t;zh:座席通话时长},  login_t={en:login_t;zh:登录时长}', null, '', '', '', '', '', 'SkillIn_n=0, Ans_nds=0%, AnsLess_nds=0%, Ans_tdn=0, Aban_n=0, Aban_nds=0%, AbanSkill_nda=0%, AbanAgent_nda=0%, Aban_tdn=0, Ans_tdn=time_sec, CallIn_t=time_sec, Login_t=time_sec,  maxans_t=time_sec,  aban_tdn=time_sec', '', '', '', 'TimeRange=Time,PrjId=项目,Agents=座席,SkillList=技能组', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('cd.stat.call.report.year', '呼叫年统计报表', 100, '', 60300000, 35, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, '', '', 'cd.stat.call.sch.jsp', '', '', '', '', '', '', '', '', '', '', '', '', null, 'vxi_crm..sp_chengdu_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, null, null, null, null, 'RepDate=统计日期', null, null, null, null, null, null, 'SkillIn_n=0, Ans_nds=0%, AnsLess_nds=0%, Ans_tdn=0, Aban_n=0, Aban_nds=0%, AbanSkill_nda=0%, AbanAgent_nda=0%, Aban_tdn=0, CallIn_ht=3, Login_ht=3', null, null, null, 'YearSch=RepDate,PrjId=项目,Agents=座席,SkillList=技能组', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('cd.stat.ivr.call.report', 'IVR呼叫统计报表', 100, '', 40200000, 35, 1, 15, 15, -1, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'search.grid.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_crm..sp_chengdu_stat_call_work', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'itemNo={zh:序号;en:No.},  describe={zh:统计项(描述);en:Describe},  amount={zh:数量;en:Amount}', null, '', '', '', '', '', '', '', '', '', 'TimeRange=Time', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('cti.route.rec', '{en:IRS Records,zh:智能路由记录}', 100, '0', 30200000, 33, 1, 15, 15, -1, 'vxi_ucd..routerecord', 'routeid', 1, 0, null, '', '', null, null, null, null, '', 1000, null, 'ext.search.jsp', null, null, 'cti.route.rec.jsp', 'cti.route.rec.jsp', 'cti.route.rec.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', null, null, '', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', '', null, 'routeid={en:ID;zh:路由代码},   UcdId={en:UCDID;zh:统一联络代码},   CallId={en:Call ID;zh:呼叫代码},   Calling={en:Calling No.;zh:主叫号码},   Called={en:Called No.;zh:被叫号码},   Route={en:Route;zh:路由点},   StartTime={en:Start Time;zh:开始时间},   TimeLen={en:Route Time Lengthen;zh:时长},   RouteTo={en: Route To;zh:路由目的地},   DevType={en:Device Type;zh:设备类型},   Result={en:Error Code;zh:错误代码}', null, null, null, null, null, '', 'TimeLen=timestamp', null, '', null, 'routeid=Route ID, UcdId=UCDID, CallId=Call ID, Calling=Calling No., Called=Called No., Route=Route, RouteTo=Route To, DateRange=StartTime', 'select m.routeid, m.UcdId, m.CallId, m.Calling, m.Called, m.Route, m.StartTime, m.TimeLen, m.RouteTo, m.DevType, m.Result from vxi_ucd..routerecord m', 'select m.routeid, m.UcdId, m.CallId, m.Calling, m.Called, m.Route, m.StartTime, m.TimeLen, m.RouteTo, m.DevType, m.Result from vxi_ucd..routerecord m where m.routeid = !routeid', 'select m.routeid from vxi_ucd..routerecord m where m.routeid = !routeid', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 0, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('datawin', '{zh:数据集定义, en:Record Set Defination}', 100, '', 10100000, 1, 15, 15, 15, 8388607, 'DataWin', 'DataWin', 0, null, null, '', '', null, null, '', null, '', 1000, 0, 'ext.search.jsp', '', 'schcombox.jsp', 'datawin.jsp', 'datawin.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'syn=dict:datawin  syn=datawin', 'syn=dict:datawin  syn=datawin', 'syn=dict:datawin  syn=datawin', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'DataWin=数据集, dwTitle=标题, dwType=查询类型, KeyField=主键字段, dwSQL=查询语句, Rows=行数, Cols=列数, Enabled=启用标志', null, null, null, null, null, '', '', null, '', null, 'DataWin=数据集, dwTitle=标题', 'select m.DataWin, m.dwType, m.KeyField, m.Rows, m.Cols from DataWin m', 'select m.DataWin, m.dwTitle, m.dwType, m.KeyField, m.dwSQL, m.Fields, m.Rows, m.Cols, m.Acked, m.Enabled from DataWin m where m.DataWin = !DataWin', 'select m.DataWin, m.dwTitle, m.dwType, m.KeyField, m.dwSQL, m.Fields, m.Rows, m.Cols, m.Acked, m.Enabled from DataWin m where m.DataWin = !DataWin', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, null, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('dblink', '{zh:数据库链接定义, en:Database Link Setting}', 100, '0', 10300000, 3, 7, 15, 15, -1, 'dblink', 'dblink', 0, 0, null, '', '', 0, 0, '', '', '', 1000, 0, 'ext.search.jsp', '', '', 'dblink.jsp', 'dblink.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'dblink={zh:数据链接名称; en:DB Link Name}, Host＝{zh:主机地址; en:Host Address}, DbType={zh:数据库类型; en:Database Type}, SplitKey={zh:分列字段; en:Split Field}, SplitValue={zh:分列数值;en:Split Value}, LogUser={zh:连接账号; en:User Name}, LogPass={zh:连接密码; en:Password}', '', '', '', '', '', '', '', '', '', '', 'dblink, Host, Enabled', 'select m.dblink, m.Host, m.LogUser, m.DbType, m.SplitKey, m.SplitValue, m.ActFlag Applied, m.Enabled from dblink m', 'select m.dblink, m.Host, m.LogUser, m.LogPass, m.DbType, m.SplitKey, m.SplitValue, m.ActFlag, m.Summary, m.Enabled from dblink m where m.dblink = !dblink', 'select m.dblink, m.Host, m.LogUser, m.LogPass, m.DbType, m.SplitKey, m.SplitValue, m.Summary, m.Enabled from dblink m where m.dblink = !dblink', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, '', '', '', null, null, null, null, null, null, null, null, 1, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('def.dict', '{zh:自定义常量字典, en:Constants Setting}', 100, '', 10100000, 2, 7, 15, 15, -1, 'define', 'keyid', 1, 1, null, 'defitem', 'keyfield', 0, null, '', null, '', 1000, 0, 'ext.search.jsp', '', 'schcombox.jsp', 'def.dict.jsp', 'def.dict.jsp', '', '', '', '', 'search.jsp', 'def.dict.item.jsp', 'def.dict.item.jsp', '', '', '', null, '', '', '', '', '', '', 'syn=dict', 'syn=dict', 'syn=dict', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'keyid={zh:字典代码;en:Dictionary ID},  KeyName={zh:字典名称;en:Dictionary Name},  Enabled={zh:有效状态;en:Enabled},  keyfield={zh:字典字段;en:Field},  KeyValue={zh:字典显示;en:View},  KeyOrder={zh:排序字段;en:Order}', null, null, null, null, null, '', '', null, '', null, 'keyid=字典代码,   KeyName=字典名称', 'select m.keyid, m.KeyName, m.Enabled from define m order by m.keyid', 'select m.keyid, m.KeyName, m.Enabled from define m where m.keyid = !keyid', 'select m.keyid, m.KeyName, m.Enabled from define m where m.keyid = !keyid', '', '', '', 'keyid={zh:字典代码;en:Dictionary ID},  KeyName={zh:字典名称;en:Dictionary Name},  Enabled={zh:有效状态;en:Enabled},  keyfield={zh:字典字段;en:Field},  KeyValue={zh:字典显示;en:View},  KeyOrder={zh:排序字段;en:Order}', null, 'select m.keyid, s.keyfield, m.KeyName, s.KeyValue, s.KeyOrder from define m inner join defitem s on m.keyid = s.keyid order by m.keyid, s.KeyOrder', 'select m.keyid, s.keyfield, s.KeyValue, s.KeyOrder from define m inner join defitem s on m.keyid = s.keyid where m.keyid = !keyid order by s.KeyOrder', 'select m.keyid, s.keyfield, s.KeyValue, s.KeyOrder from define m inner join defitem s on m.keyid = s.keyid where m.keyid = !keyid and s.keyfield = !keyfield', 'select m.keyid, s.keyfield, m.KeyName, s.KeyValue, s.KeyOrder from define m inner join defitem s on m.keyid = s.keyid where m.keyid = !keyid and s.keyfield = !keyfield', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, null, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('dictionary', '{zh:系统字典定义, en:System Dictionary Setting}', 100, '0', 10100000, 3, 15, 15, 15, -1, 'dictionary', 'dicname', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', '', 'schcombox.jsp', 'dictionary.jsp', 'dictionary.jsp', 'dictionary.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', null, null, '', '', '', null, '', '', 'syn=dict', 'syn=dict', 'syn=dict', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'dicname={zh:字典名称;en:Dictionary Name},  keytable={zh:数据表;en:Table},  keyfield={zh:字典字段;en:Field},  SortField={zh:分组字段;en:Sort Field},  valuefield={zh:字典显示;en:View},  orderfield={zh:排序字段;en:Order},  filters={zh:条件表达式;en: Filter},  Enabled={zh:字典状态;en:Enabled}', null, null, null, null, null, '', '', null, '', null, 'dicname=字典名称', 'select m.dicname, m.keytable, m.SortField, m.keyfield, m.valuefield, m.orderfield, m.enabled from dictionary m', 'select m.dicname, m.KeyTable, m.SortField, m.KeyField, m.ValueField, m.OrderField, m.Filters, m.SqlText, m.Acked, m.Enabled from dictionary m where m.dicname = !dicname', 'select m.dicname, m.KeyTable, m.SortField, m.KeyField, m.ValueField, m.OrderField, m.Filters, m.SqlText, m.Acked, m.Enabled from dictionary m where m.dicname = !dicname', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 1, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('email.service', '{en:Email Connection Service,zh:Email 接入服务}', 100, null, 20600000, 1, 7, 15, 15, 16777089, 'vxi_sys..EmailService', 'id', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.search.jsp', '', '', 'email.service.jsp', 'email.service.jsp', '', '', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'id={en:id;zh:标识},  UserID={en:Email Accounts;zh:Email帐号},  Password={en:Password;zh:密码},  PopHost={en:Pop Host;zh:Pop主机},  PopPort={en:Pop Port;zh:Pop端口},  SmtpHost={en:Smtp Host;zh:Smtp主机},  SmtpPort={en:Smtp Port;zh:Smtp端口},  RetrieveInterval={en:Retrieve Interval;zh:检测间隔},  ServerName={en:Server Name;zh:邮件服务器名},  Skill={en:Skill;zh:技能组},  Priority={en:Priority;zh:优先级},  Enabled={en:Enabled;zh:有效标志}', '<fieldx>   <field name="id" owner="master">    <type></type>    <title>{en:id;zh:标识}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey>yes</tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="userid" owner="master">    <type></type>    <title>{en:Email Accounts;zh:Email帐号}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>50</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="pophost" owner="master">    <type></type>    <title>{en:Pop Host;zh:Pop主机}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>50</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="popport" owner="master">    <type></type>    <title>{en:Pop Port;zh:Pop端口}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="smtphost" owner="master">    <type></type>    <title>{en:Smtp Host;zh:Smtp主机}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>50</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="smtpport" owner="master">    <type></type>    <title>{en:Smtp Port;zh:Smtp端口}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="retrieveinterval" owner="master">    <type></type>    <title>{en:Retrieve Interval;zh:检测间隔}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="servername" owner="master">    <type></type>    <title>{en:Server Name;zh:邮件服务器名}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>30</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="skill" owner="master">    <type></type>    <title>{en:Skill;zh:技能组}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="priority" owner="master">    <type></type>    <title>{en:Priority;zh:优先级}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="enabled" owner="master">    <type></type>    <title>{en:Enabled;zh:有效标志}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>  </fieldx>  ', null, null, null, null, null, null, null, null, null, 'id=id, UserID=UserID, PopHost=PopHost, PopPort=PopPort, SmtpHost=SmtpHost, SmtpPort=SmtpPort, RetrieveInterval=RetrieveInterval, ServerName=ServerName, Skill=Skill, Priority=Priority, Enabled=Enabled', 'select m.id, m.UserID,  m.PopHost, m.PopPort, m.SmtpHost, m.SmtpPort, m.RetrieveInterval, m.ServerName, m.Skill, m.Priority from vxi_sys..EmailService m', 'select m.id, m.UserID,m.PopHost, m.PopPort, m.SmtpHost, m.SmtpPort, m.RetrieveInterval, m.ServerName, m.Skill, m.Priority, m.Enabled from vxi_sys..EmailService m where m.id = !id', 'select m.id, m.UserID, m.Password, m.PopHost, m.PopPort, m.SmtpHost, m.SmtpPort, m.RetrieveInterval, m.ServerName, m.Skill, m.Priority, m.Enabled from vxi_sys..EmailService m where m.id = !id', null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('extension', '{en:Extension Setting, zh:分机设置}', 100, '0', 20100000, 11, 7, 15, 15, -1, 'vxi_sys..devices', 'device', 0, 0, null, '', '', 0, 0, '', '', '', 1000, 0, 'ext.edit.search.jsp', '', '', 'extension.jsp', 'extension.jsp', 'extension.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'syn=dict:ext  send=VisionCTI  send=VisionEMS  send=VisionLog  sp=vxi_ucd..sp_syn_rt_device @device=!device', 'syn=dict:ext  send=VisionCTI  send=VisionEMS  send=VisionLog  sp=vxi_ucd..sp_syn_rt_device @device=!device', 'syn=dict:ext  send=VisionCTI  send=VisionEMS  send=VisionLog  sp=vxi_ucd..sp_syn_rt_device @device=!device', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', 'sortid=20100000,devtype=1', '', 'device={en:Extension; zh:分机}, sort={en:Sort; zh:分类}, devname={en:Ext. Name; zh:分机名称},   Station={en:Computer; zh:计算机}, Enabled={en:Status; zh:状态}', '', '', '', '', '', '', '', '', '', '', 'device=Extension, Station=Computer, devname=Ext. Name', 'select m.device,  m.devname, m.station, m.enabled, m.ip, m.mac from vxi_sys..devices m left join sort t on m.sortid = t.sortid where m.devtype = 1', 'select m.device, m.sortid, m.devname, m.station, m.enabled, m.ip, m.mac from vxi_sys..devices m where m.device = !device', 'select m.device, m.sortid, m.devname, m.station, m.enabled, m.ip, m.mac from vxi_sys..devices m where m.device = !device', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, '', '', '', null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('favorites', '{zh:收藏管理,en:Favorites Manage}', 100, '0', 10200000, 2, 7, 15, 15, 16777214, 'Favorite', 'favorid', 1, 1, null, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', 'calendar.jsp', 'schcombox.jsp', 'favorites.jsp', 'favorites.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'syn=favorite', 'syn=favorite', 'syn=favorite', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'FavorId={en:Favorite ID;zh:收藏代码},Title={en:Title;zh:标题},URL={en:URL;zh:链接},Note={en:Description;zh:描述},Enabled={en:Status;zh:状态}', null, null, null, null, null, '', '', null, '', null, 'url=url,note=note,title=title,note=note,enabled=enabled', 'SELECT         FavorId        ,Title        ,Note        ,Enabled    FROM vxi_def..Favorite where UserId=''{usrid}''', 'SELECT   *    FROM vxi_def..Favorite where favorid=!favorid and  UserId=''{usrid}''', 'SELECT   *    FROM vxi_def..Favorite where favorid=!favorid and  UserId=''{usrid}''', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, '', '', '', null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('flow', '{zh:控制流程定义, en:Work Flow Setting}', 100, '', 10100000, 1, 15, 15, 15, -1, 'Flow', 'FlowId', 1, 1, null, 'Node', 'NodeId', 1, 1, '', null, '', 1000, 0, 'ext.search.jsp', '', 'schcombox.jsp', 'flow.jsp', 'flow.jsp', '', '', '', '', 'search.jsp', 'flow.item.jsp', 'flow.item.jsp', '', '', null, null, '', '', '', null, '', '', 'syn=dict:flowid  syn=flow', 'syn=dict:flowid  syn=flow', 'syn=dict:flowid  syn=flow', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', '', null, null, null, null, null, '', '', null, '', null, 'FlowId=流程代码, FlowName=流程名称, SortId=分类, CtrlLoc=控制位, FlowTab=流程控制表, FlowKey=流程主键, Fields=字段描述', 'select m.FlowId, m.FlowName, m.FlowTitle, m.SortId, m.CtrlLoc, m.FlowTab, m.FlowFlag, m.Nodes, m.Root, m.FlowIcon from Flow m', 'select m.FlowId, m.FlowName, m.FlowTitle, m.SortId, m.CtrlLoc, m.FlowTab, m.FlowKey, m.Fields, m.FlowFlag, m.Nodes, m.Root, m.FlowIcon, m.Enabled from Flow m where m.FlowId = !FlowId', 'select m.FlowId, m.FlowName, m.FlowTitle, m.SortId, m.CtrlLoc, m.FlowTab, m.FlowKey, m.Fields, m.FlowFlag, m.Nodes, m.Root, m.FlowIcon, m.Enabled from Flow m where m.FlowId = !FlowId', '', '', '', 'FlowId={zh:流程代码;en:FlowId},  FlowName={zh:流程名称;en:FlowName},  SortId={zh:分类;en:SortId},  CtrlLoc={zh:控制位;en:CtrlLoc},  FlowTab={zh:流程控制表;en:FlowTab},  FlowKey={zh:流程主键;en:FlowKey},  Fields={zh:字段描述;en:Fields},  NodeId={zh:节点代码;en:NodeId}  ', null, 'select m.FlowId, s.NodeId, s.NodeType, s.NodeName, s.SupNode, s.ModId, s.Oper, s.ActId, s.LinkFile, s.LinkURL, s.DataWin, s.NodeLoc, s.AllReady, s.PartReady, s.NotReady, s.Width, s.Height from Flow m inner join Node s on m.FlowId = s.FlowId', 'select m.FlowId, s.NodeId, s.NodeType, s.NodeName, s.ModId, s.Oper, s.LinkFile, s.DataWin, s.NodeLoc from Flow m inner join Node s on m.FlowId = s.FlowId where m.FlowId = !FlowId order by s.NodeId', 'select m.FlowId, s.NodeId, s.NodeType, s.NodeName, s.SupNode, s.ModId, s.Oper, s.ActId, s.LinkFile, s.LinkURL, s.DataWin, s.ExecSql, s.NodeLoc, s.AllReady, s.PartReady, s.NotReady, s.Popup, s.saves, s.loads,  s.Width, s.Height, s.Enabled from Flow m inner join Node s on m.FlowId = s.FlowId where m.FlowId = !FlowId and s.NodeId = !NodeId', 'select m.FlowId, s.NodeId, s.NodeType, s.NodeName, s.SupNode, s.ModId, s.Oper, s.ActId, s.LinkFile, s.LinkURL, s.DataWin, s.ExecSql, s.NodeLoc, s.AllReady, s.PartReady, s.NotReady, s.Popup, s.saves, s.loads, s.Width, s.Height, s.Enabled from Flow m inner join Node s on m.FlowId = s.FlowId where m.FlowId = !FlowId and s.NodeId = !NodeId', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, null, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('groups', '{zh:设备分组信息, en:Group Information}', 100, '0', 20400000, 14, 15, 15, 15, 16777215, 'vxi_sys..groups', 'groupid', 1, 1, null, '', '', null, null, '', '', '', 1000, 0, 'ext.search.jsp', '', '', 'groups.jsp', 'groups.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'syn=dict  send=VisionLog', 'syn=dict  send=VisionLog', 'syn=dict  send=VisionLog', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, '', '', '', '', 'groupid={en:Group ID;zh:分组代码},  GroupName={en:Group Name;zh:分组名称},  TypeName={en:Group Type;zh:分组类型},  Summary={en:Description;zh:分组描述},  Acked={en:Ack;zh:确认标志},  Enabled={en:Status;zh:状态}', '', '', '', '', '', '', '', '', '', '', 'groupid=Group ID, groupname=Group Name, typename=Type', 'select m.groupid, m.GroupName, t.TypeName, m.Enabled, m.acked from vxi_sys..groups m, vxi_sys..GroupType t where m.GroupType = t.GroupType', 'select m.groupid, m.GroupName, m.GroupType, m.Items, m.Summary, m.Acked, m.Enabled from vxi_sys..groups m where m.groupid = !groupid', 'select m.groupid, m.GroupName, m.GroupType, m.Items, m.Summary, m.Acked, m.Enabled from vxi_sys..groups m where m.groupid = !groupid', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, '', '', '', null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('grp.agent', '{zh:座席组定义, en:Agent Group Setting}', 100, '0', 20400000, 14, 7, 15, 15, -1, 'vxi_sys..groups', 'groupid', 1, 1, null, '', '', null, null, null, null, '', 1000, 0, 'ext.search.jsp', null, null, 'groups.jsp', 'groups.jsp', '', '', '', '', '', '', '', '', '', null, null, '', '', '', null, '', '', 'syn=dict:agtgrp  syn=dict:groupid  send=VisionLog', 'syn=dict:agtgrp  syn=dict:groupid  send=VisionLog', 'syn=dict:agtgrp  syn=dict:groupid  send=VisionLog', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'GroupType=1', null, 'groupid={en:Group ID;zh:分组代码},  GroupName={en:Group Name;zh:分组名称},  TypeName={en:Group Type;zh:分组类型},  Summary={en:Description;zh:分组描述},  Acked={en:Ack;zh:确认标志},  Items={en:Member List;zh:成员列表},    Enabled={en:Status;zh:状态}', null, null, null, null, null, '', '', null, '', null, 'groupid=Group ID, groupname=Group Name', 'select m.groupid, m.GroupName, m.GroupType, m.Enabled from vxi_sys..groups m where m.GroupType = 1', 'select m.groupid, m.GroupName, m.GroupType, m.Items, m.Summary, m.Acked, m.Enabled from vxi_sys..groups m where m.groupid = !groupid', 'select m.groupid, m.GroupName, m.GroupType, m.Items, m.Summary, m.Acked, m.Enabled from vxi_sys..groups m where m.groupid = !groupid', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('grp.ext', '{zh:分机组定义, en:Extension Group Setting}', 100, '0', 20400000, 14, 7, 15, 15, -1, 'vxi_sys..groups', 'groupid', 1, 1, null, '', '', null, null, null, null, '', 1000, 0, 'ext.search.jsp', null, null, 'ext.groups.jsp', 'ext.groups.jsp', '', '', '', '', '', '', '', '', '', null, null, '', '', '', null, '', '', 'syn=dict:extgrp  syn=dict:groupid  send=VisionLog', 'syn=dict:extgrp  syn=dict:groupid  send=VisionLog', 'syn=dict:extgrp  syn=dict:groupid  send=VisionLog', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'GroupType=2', null, 'groupid={en:Group ID;zh:分组代码},  GroupName={en:Group Name;zh:分组名称},  TypeName={en:Group Type;zh:分组类型},  Summary={en:Description;zh:分组描述},  Acked={en:Ack;zh:确认标志},  Items={en:Member List;zh:成员列表},  Enabled={en:Status;zh:状态}', null, null, null, null, null, '', '', null, '', null, 'groupid=Group ID, groupname=Group Name', 'select m.groupid, m.GroupName, m.GroupType, m.Enabled from vxi_sys..groups m where m.GroupType = 2', 'select m.groupid, m.GroupName, m.GroupType, m.Items, m.Summary, m.Acked, m.Enabled from vxi_sys..groups m where m.groupid = !groupid', 'select m.groupid, m.GroupName, m.GroupType, m.Items, m.Summary, m.Acked, m.Enabled from vxi_sys..groups m where m.groupid = !groupid', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('grp.station', '{zh:计算机组定义, en:Computer Group Setting}', 100, '0', 20400000, 14, 7, 15, 15, -1, 'vxi_sys..groups', 'groupid', 1, 1, null, '', '', null, null, null, null, '', 1000, 0, 'ext.search.jsp', null, null, 'station.groups.jsp', 'station.groups.jsp', '', '', '', '', '', '', '', '', '', null, null, '', '', '', null, '', '', 'syn=dict:stngrp  syn=dict:groupid', 'syn=dict:stngrp  syn=dict:groupid', 'syn=dict:stngrp  syn=dict:groupid', '', '', '', 'nil', '', '', null, null, null, null, null, null, null, null, null, '', '', 'GroupType=5', '', 'groupid={en:Group ID;zh:分组代码},  GroupName={en:Group Name;zh:分组名称},  grouptype={en:Group Type;zh:分组类型},  Summary={en:Description;zh:分组描述},  Acked={en:Ack;zh:确认标志},  Items={en:Member List;zh:成员列表},  Enabled={en:Status;zh:状态}', null, null, null, null, null, '', '', null, '', null, 'groupid=Group ID, groupname=Group Name', 'select m.groupid, m.GroupName, m.GroupType, m.Enabled from vxi_sys..groups m where m.GroupType = 5', 'select m.groupid, m.GroupName, m.GroupType, m.Items, m.Summary, m.Acked, m.Enabled from vxi_sys..groups m where m.groupid = !groupid', 'select m.groupid, m.GroupName, m.GroupType, m.Items, m.Summary, m.Acked, m.Enabled from vxi_sys..groups m where m.groupid = !groupid', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('ivr.ch', '{zh:IVR通道定义, en:IVR Channel Setting}', 100, '0', 20200000, 12, 7, 15, 15, -1, 'vxi_sys..channels', 'channel', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'ext.edit.search.jsp', '', '', 'ivr.ch.jsp', 'ivr.ch.jsp', 'ivr.ch.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'syn=dict  send=VisionIVR', 'syn=dict  send=VisionIVR', 'syn=dict  send=VisionIVR', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', 'sortid=20100000', '', 'channel={en:Channel ID;zh:通道代码},  Station={en:Related Server;zh:服务器},  Sort={en:Sort;zh:分类},  DevName={en:Device Name;zh:设备名称},  PortNo={en:Device Port;zh:设备端口},  Mapped={en:Associated;zh:存在关联},  Enabled={en:Status;zh:状态}', null, '', '', '', '', '', 'chtype=dict:ivr_ch', '', '', '', 'channel=Channel ID', 'select m.channel, m.Station,  m.DevName, m.PortNo, m.ChType, m.Mapped, m.Enabled  from vxi_sys..channels m left join sort t on m.sortid = t.sortid    where m.chtype / 16 = 1 or m.chtype = 1', 'select m.channel, m.Station, m.SortId, m.DevName, m.PortNo, m.ChType, m.Mapped, m.Enabled from vxi_sys..channels m where m.channel = !channel', 'select m.channel, m.Station, m.SortId, m.DevName, m.PortNo, m.ChType, m.Mapped, m.Enabled from vxi_sys..channels m where m.channel = !channel', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('ivr.records', '{zh:IVR呼叫记录查询, en:IVR Call Records}', 100, '0', 40200000, 30, 1, 15, 15, 516093, 'vxi_ivr..ivrrecords', 'IvrId', 0, 0, null, 'vxi_ivr..ivrtrack', 'subid', 1, 1, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', 'ivr.records.jsp', '', '', '', '', 'search.jsp', '', 'ivr.track.jsp', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', 'ivrflow', 'IvrId={en:Record ID;zh:记录号},  FlowId={en:Flow ID;zh:流程编号},  FlowName={en:Flow Name;zh:流程名称},  UcdId={en:UCD ID;zh:统一联络代码},  CallId={en:Call ID;zh:呼叫代码},  Calling={en:Calling No.;zh:主叫号码},  Called={en:Called No.;zh:被叫号码},  Channel={en:IVR Channel;zh:IVR通道},  StartTime={en:Start Time;zh:开始时间},  TimeLen={en:Duration;zh:时长},  ExitType={en:Exit Type;zh:结束类型}', null, null, null, null, null, '', null, null, '', null, 'IvrId=IVR ID, FlowName=Flow Name, Calling=Calling No., Called=Called No., Channel=IVR Channel, TimeLen=Duration, ExitType=Exit Type, TimeRange=StartTime', 'select * from vxi_ivr..ivrRecords_view', 'select m.IvrId, f.FlowName, m.UcdId, m.CallId, m.Calling, m.Called, m.Channel, m.StartTime, m.TimeLen, m.ExitType from vxi_ivr..ivrrecords m inner join vxi_ivr..ivrflow f on m.flowid = f.flowid  where m.IvrId = !IvrId', 'select m.IvrId, m.FlowId, m.UcdId, m.CallId, m.Calling, m.Called, m.Channel, m.StartTime, m.TimeLen, m.ExitType from vxi_ivr..ivrrecords m where m.IvrId = !IvrId', '', '', '', 'SubId=Sub-ID, NodeName=Node Name, Selection=Selection', null, '', 'select  s.subid, m.starttime, s.nodename, s.selection, s.enter, s.leave, m.ExitType, s.result from vxi_ivr..ivrrecords m, vxi_ivr..ivrtrack s where m.IvrId = s.IvrId and m.IvrId = !IvrId', 'select s.SubId from vxi_ivr..ivrrecords m, vxi_ivr..ivrtrack s where m.IvrId = !IvrId and s.SubId = !SubId', 'select s.* from vxi_ivr..ivrrecords m, vxi_ivr..ivrtrack s where m.IvrId = !IvrId and s.SubId = !SubId', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('ivr.stat.channel', '{zh:IVR通道报表, en:IVR Channel Reports}', 100, '0', 40300000, 32, 1, 15, 15, -1, '', 'repdate', 1, 0, null, '', '', 0, 0, null, null, '', 1000, null, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_ivr..sp_sch_stat_ivr_call', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=channel', null, 'ExtUTm={zh:用户挂断时长;en:User Handup Time Length},  ExtUAvgTm={zh:用户挂断平均时长;en:User Handup Average Time},  ExtINum={zh:IVR挂断数;en:IVR Handup Num},  ExtITm={zh:IVR挂断时长;en:IVR Handup Time Length},  ExtIAvgTm={zh:IVR挂断平均时长;en:IVR Handup Average Time},  ExtDNum={zh:转接挂断数量;en:Transferred Handup Num},  ExtDTm={zh:转接挂断时长;en:Transferred Handup Time Length},  ExtDAvgTm={zh:转接挂断平均时长;en:Transferred Handup Average Time},  RepDate={en:Date;zh:日期},  Channel={en:Channel Code;zh:通道号},  CallNum={en:Call Volume;zh:呼叫量},  CallTm={en:Call Duration;zh:呼叫时长},  CallAvgTm={en:Call Average Time;zh:呼叫平均时间},  MaxTm={en:MaxCall Time;zh:最长呼叫时间},  MinTm={en:MinCall Time;zh:最短呼叫时间},  ExtUNum={en:Call Handup by User;zh:用户呼叫挂断数}', null, null, null, null, null, '', 'CallTm=timestamp, CallAvgTm=timestamp, MaxTm=timestamp, MinTm=timestamp, ExtUTm=timestamp,     ExtUAvgTm=timestamp, ExtITm=timestamp, ExtIAvgTm=timestamp, ExtDTm=timestamp,   ExtDAvgTm=timestamp', null, '', null, 'DateRange=time,sch_value=Channel ID,repdate=Report Date', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('ivr.stat.flow', '{zh:IVR流程报表, en:IVR Flow Reports}', 100, '0', 40300000, 32, 1, 15, 15, -1, '', 'repdate', 1, 0, null, '', '', 0, 0, null, null, '', 1000, null, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_ivr..sp_sch_stat_ivr_call', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=flow', null, 'ExtUTm={zh:用户挂断时长;en:User Handup Time Length},  ExtUAvgTm={zh:用户挂断平均时长;en:User Handup Average Time},  ExtINum={zh:IVR挂断数;en:IVR Handup Num},  ExtITm={zh:IVR挂断时长;en:IVR Handup Time Length},  ExtIAvgTm={zh:IVR挂断平均时长;en:IVR Handup Average Time},  ExtDNum={zh:转接挂断数量;en:Transferred Handup Num},  ExtDTm={zh:转接挂断时长;en:Transferred Handup Time Length},  ExtDAvgTm={zh:转接挂断平均时长;en:Transferred Handup Average Time},  RepDate={en:Date;zh:日期},  Channel={en:Channel Code;zh:通道号},  CallNum={en:Call Volume;zh:呼叫量},  CallTm={en:Call Duration;zh:呼叫时长},  CallAvgTm={en:Call Average Time;zh:呼叫平均时间},  MaxTm={en:MaxCall Time;zh:最长呼叫时间},  MinTm={en:MinCall Time;zh:最短呼叫时间},  ExtUNum={en:Call Handup by User;zh:用户呼叫挂断数}', null, null, null, null, null, '', 'CallTm=timestamp, CallAvgTm=timestamp, MaxTm=timestamp, MinTm=timestamp, ExtUTm=timestamp,   ExtUAvgTm=timestamp, ExtITm=timestamp, ExtIAvgTm=timestamp, ExtDTm=timestamp,   ExtDAvgTm=timestamp', null, '', null, 'DateRange=time,sch_value=Flow ID,repdate=Report Date', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('ivr.stat.node', '{zh:IVR节点报表, en:IVR Node Reports}', 100, '0', 40300000, 32, 1, 15, 15, -1, '', 'repdate', 1, 0, null, '', '', 0, 0, null, null, '', 1000, null, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_ivr..sp_sch_stat_ivr_call', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=node', null, 'ExtUTm={zh:用户挂断时长;en:User Handup Time Length},  ExtUAvgTm={zh:用户挂断平均时长;en:User Handup Average Time},  ExtINum={zh:IVR挂断数;en:IVR Handup Num},  ExtITm={zh:IVR挂断时长;en:IVR Handup Time Length},  ExtIAvgTm={zh:IVR挂断平均时长;en:IVR Handup Average Time},  ExtDNum={zh:转接挂断数量;en:Transferred Handup Num},  ExtDTm={zh:转接挂断时长;en:Transferred Handup Time Length},  ExtDAvgTm={zh:转接挂断平均时长;en:Transferred Handup Average Time},  RepDate={en:Date;zh:日期},  Channel={en:Channel Code;zh:通道号},  CallNum={en:Call Volume;zh:呼叫量},  CallTm={en:Call Duration;zh:呼叫时长},  CallAvgTm={en:Call Average Time;zh:呼叫平均时间},  MaxTm={en:MaxCall Time;zh:最长呼叫时间},  MinTm={en:MinCall Time;zh:最短呼叫时间},  ExtUNum={en:Call Handup by User;zh:用户呼叫挂断数},  sch_value={en:Node ID}', null, null, null, null, null, '', 'CallTm=timestamp, CallAvgTm=timestamp, MaxTm=timestamp, MinTm=timestamp, ExtUTm=timestamp,   ExtUAvgTm=timestamp, ExtITm=timestamp, ExtIAvgTm=timestamp, ExtDTm=timestamp,   ExtDAvgTm=timestamp', null, '', null, 'DateRange=time,sch_value=Node ID,repdate=Report Date', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('ivr.stat.report', '{zh:IVR呼叫统计报表, en:IVR Call Reports}', 100, '0', 40300000, 32, 1, 15, 15, -1, '', 'repdate', 1, 0, null, '', '', 0, 0, null, null, '', 1000, null, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_ivr..sp_sch_stat_ivr_call', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', '', null, 'ExtUTm={zh:用户挂断时长;en:User Handup Time Length},  ExtUAvgTm={zh:用户挂断平均时长;en:User Handup Average Time},  ExtINum={zh:IVR挂断数;en:IVR Handup Num},  ExtITm={zh:IVR挂断时长;en:IVR Handup Time Length},  ExtIAvgTm={zh:IVR挂断平均时长;en:IVR Handup Average Time},  ExtDNum={zh:转接挂断数量;en:Transferred Handup Num},  ExtDTm={zh:转接挂断时长;en:Transferred Handup Time Length},  ExtDAvgTm={zh:转接挂断平均时长;en:Transferred Handup Average Time},  RepDate={en:Date;zh:日期},  Channel={en:Channel Code;zh:通道号},  CallNum={en:Call Volume;zh:呼叫量},  CallTm={en:Call Duration;zh:呼叫时长},  CallAvgTm={en:Call Average Time;zh:呼叫平均时间},  MaxTm={en:MaxCall Time;zh:最长呼叫时间},  MinTm={en:MinCall Time;zh:最短呼叫时间},  ExtUNum={en:Call Handup by User;zh:用户呼叫挂断数}', null, null, null, null, null, '', 'CallTm=timestamp, CallAvgTm=timestamp, MaxTm=timestamp, MinTm=timestamp, ExtUTm=timestamp,   ExtUAvgTm=timestamp, ExtITm=timestamp, ExtIAvgTm=timestamp, ExtDTm=timestamp,   ExtDAvgTm=timestamp', null, '', null, 'DateRange=time,repdate=Report Date', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('ivr.track', '{zh:IVR流程执行明细表, en:IVR Flow Track}', 100, '0', 40200000, 35, 3, 15, 15, 1039103, 'vxi_ivr..ivrtrack', 'IvrId', 1, 1, null, '', '', null, null, '', null, '', 1000, 0, 'ext.search.jsp', '', '', 'ivr.track.jsp', 'ivr.track.jsp', 'ivr.track.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', '', null, null, null, null, null, '', '', null, '', null, 'IvrId=IvrId', 'select m.IvrId, m.SubId, m.NodeName, m.Selection, m.Enter, m.Leave, m.Result from vxi_ivr..ivrtrack m', 'select m.IvrId, m.SubId, m.NodeName, m.Selection, m.Enter, m.Leave, m.Result from vxi_ivr..ivrtrack m where m.IvrId = !IvrId', 'select m.IvrId, m.SubId, m.NodeName, m.Selection, m.Enter, m.Leave, m.Result from vxi_ivr..ivrtrack m where m.IvrId = !IvrId', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('links', '{zh:功能链接定义, en:The Links Setting}', 100, '0', 10100000, 2, 15, 15, 15, -1, 'links', 'linkid', 1, 1, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', '', 'schcombox.jsp', 'links.jsp', 'links.jsp', '', '', '', '', '', '', '', '', '', null, null, '', '', '', null, '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'linkid={zh:链接代码;en:Link ID},   sort={zh:系统分类;en:Sort},   topic={zh:链接标题;en:Title},   linktime={zh:时间;en:Time},   validtime={zh:有效日期;en:Valid Time},   linkfile={zh:模板文件;en:Link File},   Enabled={zh:链接状态;en:State}', null, null, null, null, null, '', '', null, '', null, 'linkid=链接代码, sort=系统分类, topic=链接标题, linkfile=模板文件, Enabled=链接状态', 'select m.linkid, s.sort, m.topic, m.linktime, m.validtime, m.linkfile, m.enabled from links m, sort s where m.sortid = s.sortid', 'select m.linkid, m.SortId, m.Topic, m.LinkTime, m.ValidTime, m.LinkFile, m.WWW, m.Enabled from links m where m.linkid = !linkid', 'select m.linkid, m.SortId, m.Topic, m.LinkTime, m.ValidTime, m.LinkFile, m.WWW, m.Enabled from links m where m.linkid = !linkid', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 1, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('module', '{zh:功能模块定义, en:The Module Setting}', 100, '0', 10100000, 2, 15, 15, 15, -1, 'modules', 'modid', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', 'calendar.jsp', 'schcombox.jsp', 'module.jsp', 'module.jsp', 'module.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'syn=module  syn=dict', 'syn=module  syn=dict', 'syn=module  syn=dict', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'modid={zh:模块代码;en:Mod ID},  modname={zh:模块名称;en:Mod Name},  sort={zh:系统分类;en:Sort},  ctrlloc={zh:控制位;en:Ctrl},  tabname={zh:模块主表;en:Table Name},  tabkey={zh:主表主键;en:Table Key},  Enabled={zh:状态;en:State},  modindex={zh:排序号;en:Mod Index}', null, null, null, null, null, '', '', null, '', null, 'modid=模块代码, modname=模块名称, sort=系统分类, ctrlloc=控制位, tabname=模块主表, tabkey=主表主键, Enabled=状态', 'select m.modid, m.modname, sort, m.modindex, m.ctrlloc, m.tabname, m.tabkey, m.enabled    from modules m left join sort t on m.sortid = t.sortid order by m.SortId, m.ModIndex, m.Modid', 'select m.* from modules m where m.modid = !modid', 'select m.* from modules m where m.modid = !modid', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('project', '{zh:项目定义, en:Project Setting}', 100, '0', 20500000, 15, 7, 15, 15, 16727025, 'vxi_sys..projects', 'prjid', 1, 1, null, 'vxi_sys..PrjItem', 'subid', 1, 1, '', null, '', 1000, 0, 'ext.search.jsp', '', '', 'project.jsp', 'project.jsp', '', '', '', '', 'search.jsp', 'prjitem.jsp', 'prjitem.jsp', '', '', '', '', '', '', '', '', '', '', 'syn=dict:prjId', 'syn=dict:prjId', 'syn=dict:prjId', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', 'sortid=20500000', '', 'PrjId={en:Project ID; zh:项目代码}, project={en:Project Name; zh:项目名称}, Sort={en:Sort;zh:分类}, StartDay={en:Start Date;zh:开始日期}, StopDay={en:End Day;zh:结束日期}, State={en:Status;zh:状态}, subid={en:Item ID;zh:代码}, items={en:Itme;zh:选项}, typename={en:Type;zh:类型名称}, type={en:Type;zh:类型}, enabled={en:Enabled;zh:有效标志},Summary={en:Summary;zh:项目描述}', null, null, null, null, null, '', 'type=dict:prjitemtype', null, '', null, 'PrjId=Project ID, project=Project Name', 'select m.PrjId, m.project, t.Sort, m.StartDay, m.StopDay, m.State, m.enabled from vxi_sys..projects m left join sort t on m.sortid = t.sortid', 'select m.project, m.PrjId, m.SortId, m.Summary, m.StartDay, m.StopDay, m.State, m.Enabled from vxi_sys..projects m where m.prjid = !prjid', 'select m.project, m.PrjId, m.SortId, m.Summary, m.StartDay, m.StopDay, m.State, m.Enabled from vxi_sys..projects m where m.prjid = !prjid', '', '', '', 'PrjId=Project ID, project=Project Name, items=Device, typename=Type', null, 'select m.prjid, s.subid, m.project, s.items, p.TypeName, s.enabled from vxi_sys..projects m inner join vxi_sys..prjitem s on m.prjid = s.prjid left join vxi_sys..prjitemtype p on s.type = p.type', 'select m.prjid, s.subid, s.type, s.items, s.enabled from vxi_sys..projects m inner join vxi_sys..prjitem s on m.prjid = s.prjid left join vxi_sys..prjitemtype p on s.type = p.type where m.prjid = !prjid', 'select s.* from vxi_sys..projects m inner join vxi_sys..prjitem s on m.prjid = s.prjid where m.prjid = !prjid and s.subid = !subid', 'select s.* from vxi_sys..projects m inner join vxi_sys..prjitem s on m.prjid = s.prjid where m.prjid = !prjid and s.subid = !subid', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rec.bf', '{zh:录音系统数据备份, en:VisionLog Data Backup}', 100, null, 50300000, 22, 7, 15, 15, -1, 'vxi_sys..Station', 'station', 1, 1, null, null, null, null, null, null, null, null, 1000, 0, 'ext.search.jsp', null, null, 'maintain.jsp', 'maintain.jsp', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'select m.station, s.ip, m.username, m.password from vxi_rec..Store m inner join vxi_sys..Station s on m.station = s.station    where m.enabled = 1', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rec.ch', '{zh:VRS录音通道定义, en:VRS Recording Channel Setting}', 100, '0', 20200000, 12, 7, 15, 15, -1, 'vxi_sys..channels', 'channel', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, 'ext.edit.search.jsp', '', '', 'rec.ch.jsp', 'rec.ch.jsp', 'rec.ch.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'syn=dict  send=VisionVRS', 'syn=dict  send=VisionVRS', 'syn=dict  send=VisionVRS', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', 'sortid=20100000', '', 'channel={en:Channel ID; zh:通道号}, Station={en:Related Server; zh:关联服务器}, Sort={en:Sort; zh:分类}, DevName={en:Device Name; zh:设备名称}, PortNo={en:Device Port; zh:端口号}, VoiceType={en:Voice Type; zh:语音文件类型}, Mapped={en:Associated; zh:存在关联}, Enabled={en:Status; zh:状态}', null, null, null, null, null, '', 'chtype=dict:rec_ch', null, '', null, 'channel=Channel ID', 'select m.channel, m.Station,  m.DevName, m.PortNo, m.VoiceType, m.ChType, m.Mapped, m.Enabled from vxi_sys..channels m left join sort t on m.sortid = t.sortid    where m.chtype / 16 = 2', 'select m.channel, m.Station, m.SortId, m.DevName, m.PortNo, m.VoiceType, m.ChType, m.Mapped, m.Enabled from vxi_sys..channels m where m.channel = !channel', 'select m.channel, m.Station, m.SortId, m.DevName, m.PortNo, m.VoiceType, m.ChType, m.Mapped, m.Enabled from vxi_sys..channels m where m.channel = !channel', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rec.clauses', '{zh:句管理, en:Clause Manage}', 100, '', 20700000, 17, 7, 15, 15, -1, 'vxi_rec.asr.clauses', 'ClauseId', 1, 1, null, 'vxi_rec.asr.clause', 'LogId', 1, 1, '', '', '', 1000, 0, 'ext.search.jsp', '', '', 'rec.clauses.jsp', 'rec.clauses.jsp', '', '', '', '', 'search.jsp', 'rec.clauses.item.jsp', 'rec.clauses.item.jsp', '', '', '', '', null, '', '', '', '', '', 'syn=dict:clauseid', 'syn=dict:clauseid', 'syn=dict:clauseid', '', '', '', '', '', '', '', '', '', '', '', '', '', '', null, null, null, null, null, 'ClauseId={zh:句编号; en:ClauseId},  Decription={zh:描述; en:Description},  Enabled={zh:状态; en:Status},  LogId={zh:明细编号; en:ItemId},  Clause={zh:句; en:Clause}     ', null, null, null, null, null, null, null, null, null, null, 'ClauseId=ClauseId', 'select m.ClauseId, m.decription, m.Enabled from vxi_rec.asr.clauses m', 'select m.ClauseId, m.Decription, m.Enabled from vxi_rec.asr.clauses m where m.ClauseId = !ClauseId', 'select m.ClauseId, m.Decription, m.Enabled from vxi_rec.asr.clauses m where m.ClauseId = !ClauseId', null, null, null, 'Clause=Clause', null, 'select m.ClauseId, s.Clause, s.logid  from vxi_rec.asr.clauses m inner join vxi_rec.asr.clause s on m.ClauseId = s.ClauseId', 'select m.ClauseId, s.logid, s.Clause from vxi_rec.asr.clauses m inner join vxi_rec.asr.clause s on m.ClauseId = s.ClauseId where m.ClauseId = !ClauseId order by s.LogId', 'select m.ClauseId, s.Clause, s.Enabled from vxi_rec.asr.clauses m inner join vxi_rec.asr.clause s on m.ClauseId = s.ClauseId where m.ClauseId = !ClauseId and s.LogId = !LogId', 'select m.ClauseId, s.Clause, s.Enabled from vxi_rec.asr.clauses m inner join vxi_rec.asr.clause s on m.ClauseId = s.ClauseId where m.ClauseId = !ClauseId and s.LogId = !LogId', null, null, null, null, null, 1, '', '', '', null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rec.ext.stat', '{zh:录音系统分机统计报表,en:Recording Extension Statistic Report}', 100, null, 50500000, 44, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.search.jsp', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep..sp_stat_record_ext_report @GroupByExt=1,@Language=!language,@SplitTm=60,@stat=1', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'date_group', null, null, null, null, null, null, null, null, null, null, null, 'prjid,extensions,TimeFrame=Time:PeriodTime', null, null, null, null, null, null, null, 'extension=extension', null, null, null, null, null, null, null, null, null, null, '1', '1', null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rec.inbound.stat', '{zh:录音系统呼入统计报表,en:Recording Inbound Statistic Report}', 100, '', 50500000, 44, 1, 15, 15, -1, '', '', null, null, null, '', '', null, null, '', '', '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_record_inbound_outbound_report  @Language=!language,@SplitTm=60,@stat=1,@IsInbound=1', '', '', '', '', '', '', '', '', '', '', '', '', '', '', null, null, null, null, 'date_group', null, null, null, null, null, null, null, null, null, null, null, 'prjid,extensions,TimeFrame=Time:PeriodTime', null, null, null, null, null, null, null, 'DateSch=RepDate, extension=extension', null, null, null, null, null, null, null, null, null, null, '1', '1', '', '', '', null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rec.log', '{zh:Log录音记录查询, en:VisionLog Records}', 100, '0', 50200000, 42, 3, 15, 15, -1, 'vxi_rec..records', 'recordid', 1, 1, null, '', '', null, null, '', null, '', 1000, 0, 'log.search.jsp', '', '', 'rec.log.vmp.jsp', 'rec.log.vmp.jsp', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rec..sp_sch_records @recordid=!recordid,@num_begin=!num_begin,@num_end=!num_end,@Called=!called,@Calling=!calling,@skill=!skill,@Extension=!device,@agent=!agent,@label=!label,@custom=!custom,@groupid=!groupid,@taskid=!taskid,@prjid=!prjid, @audioasr=!audioasr, @confidence=!confidence, @ucdid=!ucdid, @itemkey=!itemkey, @itemvalue=!itemvalue, @finished=!finished', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', 'prjid=@projectid,agent=@agentlist,skill=@skilllist,taskid=@tasklist,groupid=@grouplist,device=@extlist', '', 'recordid={en:Record ID;zh:记录号},   UcdId={en:UCD ID;zh:统一联络代码},   Calling={en:Calling No.;zh:主叫号码},   Called={en:Called No.;zh:被叫号码},   Answer={en:Answered;zh:应答号码},   StartTime={en:Start Time;zh:开始时间},   TimeLen={en:Duration(Sec);zh:时长},   device={en:Extension;zh:分机},   Agent={en:Agent;zh:座席},   Skill={en:Skill;zh:技能组},  seconds={en:Duration(Sec);zh:时长},  type={en:Call Type;zh:呼叫类型},  item01={en:Item 01;zh:扩展01},  item02={en:Item 02;zh:扩展02},  item03={en:Item 03;zh:扩展03},  prjid={en:Project ID;zh:项目代码},  groupid={en:Agent Group;zh:坐席组},  taskid={en:Task ID;zh:任务代码},  calltype={en:Call Type;zh:呼叫类型},  seconds={en:Seconds; zh:时长},  starttime={en:Start Time; zh:开始时间},  label={en:Label;zh:包含标签},  custom={en:Custom No;zh:客户号码},  Master={en:Agent;zh:座席},  Trunk={en:Trunk;zh:中继号},  audioASR={en:Audio Content;zh:语音内容}  ', '<fieldx>   <field name="recordid" owner="master">    <type></type>    <title>{en:Record ID;zh:记录号}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey>yes</tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="ucdid" owner="master">    <type></type>    <title>{en:UCD ID;zh:统一联络代码}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="calling" owner="master">    <type></type>    <title>{en:Calling No.;zh:主叫号码}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="called" owner="master">    <type></type>    <title>{en:Called No.;zh:被叫号码}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="answer" owner="master">    <type></type>    <title>{en:Answered;zh:应答号码}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="starttime" owner="master">    <type></type>    <title>{en:Start Time;zh:开始时间}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="timelen" owner="master">    <type></type>    <title>{en:Duration(Sec);zh:时长}</title>    <dict>stamp</dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="agent" owner="master">    <type></type>    <title>{en:Agent;zh:座席}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="skill" owner="master">    <type></type>    <title>{en:Skill;zh:技能组}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="videourl" owner="master">    <type></type>    <title>VideoURL</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="audiourl" owner="master">    <type></type>    <title>AudioURL</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="channel" owner="master">    <type></type>    <title>Channel</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="extension" owner="master">    <type></type>    <title>{en:Extension;zh:分机}</title>    <dict>:ext</dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="voicetype" owner="master">    <type></type>    <title>VoiceType</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="startdate" owner="master">    <type></type>    <title>StartDate</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="starthour" owner="master">    <type></type>    <title>StartHour</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="inbound" owner="master">    <type></type>    <title>Inbound</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="outbound" owner="master">    <type></type>    <title>Outbound</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="finsihed" owner="master">    <type></type>    <title>Finsihed</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="labeled" owner="master">    <type></type>    <title>Labeled</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="actflag" owner="master">    <type></type>    <title>ActFlag</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="prjid" owner="master">    <type></type>    <title>{en:Project ID;zh:项目代码}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="ucid" owner="master">    <type></type>    <title>ucid</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>25</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>  </fieldx>  ', null, '', null, null, '', 'TimeLen=timestamp,  LabelTime=datetime,  seconds=time_sec,  groupid=dict:agtgrp,  type=dict:calltype,  device=dict:ext,  itemkey=dict:itemkv,', null, '', null, 'recordid=Record ID, UcdId=UCD ID, Calling=Calling No., Called=Called No., Answer=Answer No., TimeRange=StartTime,  agent=Agent,  skill=Skill, Device=Device,  NumRange=seconds,  taskid=Task ID,TopDays=1,  groupid=Agent Group,  prjid=Project ID,  type=Call Type,  label=label,  audioASR=audioASR,  custom=custom,  confidence=confidence,  itemkey=itemkey,  itemvalue=itemvalue,  finished=finished,    ', null, 'select m.recordid, m.UcdId, isnull(c.Calling, m.Calling) Calling, isnull(c.Called, m.Called) Called, isnull(c.Answer, m.Answer) Answer, m.StartTime, m.TimeLen, m.Agent, m.Skill, m.VideoURL, m.AudioURL, m.Channel, m.Extension, m.VoiceType, m.StartDate, m.StartHour, m.Inbound, m.Outbound, m.Finished, m.Labeled, m.ActFlag,m.prjid,m.ucid from vxi_rec..records m left join vxi_ucd..ucdcall c on m.ucdid = c.ucdid and m.callid = c.callid where m.recordid = !recordid', null, '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rec.outbound.stat', '{zh:录音系统呼出统计报表,en:Recording Outbound Statistic Report}', 100, '', 50500000, 44, 1, 15, 15, -1, '', '', null, null, null, '', '', null, null, '', '', '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_record_inbound_outbound_report  @Language=!language,@SplitTm=60,@stat=1,@IsInbound=0', '', '', '', '', '', '', '', '', '', '', '', '', '', '', null, null, null, null, 'date_group', null, null, null, null, null, null, null, null, null, null, null, 'prjid,extensions,TimeFrame=Time:PeriodTime', null, null, null, null, null, null, null, 'DateSch=RepDate, extension=extension', null, null, null, null, null, null, null, null, null, null, '1', '1', '', '', '', null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rec.package', '{zh:词库管理, en:Package Manage}', 100, null, 20700000, 17, 7, 15, 15, -1, 'vxi_rec.asr.package', 'PkgId', 1, 1, null, null, null, null, null, null, null, null, 1000, 0, 'ext.search.jsp', '', '', 'rec.package.jsp', 'rec.package.jsp', '', '', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'PkgId={zh:词库编号; en:PkgId},  Words={zh:词; en:Words},  Clauses={zh:句; en:Clauses},  Description={zh:描述; en:Description},  Enabled={zh:状态; en:Status}  ', null, null, null, null, null, null, null, null, null, null, 'PkgId=PkgId', 'select m.PkgId, m.words, m.Clauses, m.Description, m.enabled from vxi_rec.asr.package m', 'select m.PkgId, m.Words, m.Clauses, m.Description, m.Enabled from vxi_rec.asr.package m where m.PkgId = !PkgId', 'select m.PkgId, m.Words, m.Clauses, m.Description, m.Enabled from vxi_rec.asr.package m where m.PkgId = !PkgId', null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rec.prj.stat', '{zh:录音系统项目统计报表,en:Recording Project Statistic Report}', 100, '', 50500000, 44, 1, 15, 15, -1, '', '', null, null, null, '', '', null, null, '', '', '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_record_ext_report @GroupByExt=0,@Language=!language,@SplitTm=60,@stat=1,@GroupByPrj=1', '', '', '', '', '', '', '', '', '', '', '', '', '', '', null, null, null, null, 'date_group', null, null, null, null, null, null, null, null, null, null, null, 'prjid,extensions,TimeFrame=Time:PeriodTime', null, null, null, null, null, null, null, 'prjid=prjid', null, null, null, null, null, null, null, null, null, null, '1', '1', '', '', '', null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rec.task', '{zh:Log录音任务设置, en:Recording Task Setting}', 100, '0', 50100000, 41, 7, 15, 15, 16777167, 'vxi_rec..task', 'taskid', 1, 1, null, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', '', '', 'rec.task.jsp', 'rec.task.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'syn=dict:taskid  send=VisionLog', 'syn=dict:taskid  send=VisionLog', 'syn=dict:taskid  send=VisionLog', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', 'SortID=50100000', '', 'taskid={en:Task ID;zh:任务代码},  SortId={en:Sort ID;zh:分类代码},  TaskName={en:Task Name;zh:任务名称},  Items={en:Task List;zh:任务列表},  TaskType={en:Time Type;zh:时间类型},  DevType={en:Device Type;zh:设备类型},  Quality={en:Quality;zh:声音品质},  State={en:State;zh:状态},  WeekMark={en:Weekly Task;zh:每周任务},  MonthMark={en:Monthly Task;zh:每月任务},  DateStart={en:Start Date;zh:开始日期},  DateEnd={en:End Date;zh:结束日期},  TimeStart={en:Start Time;zh:开始时间},  TimeEnd={en:End Time;zh:结束时间},  RecFlag={en:Flag;zh:记录类型},  AsrFlag={en:AsrFlag; zh:语音分析},  AsrPercent={zh:语音分析率(%); en:Asr Percent(%)},   AsrPkgs={en:AsrPkgs; zh:所用词库},  enabled={en:Record Task;zh:录音任务}    ', '<fieldx>   <field name="taskid" owner="master">    <type></type>    <title>{en:Task ID;zh:任务代码}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey>yes</tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="sortid" owner="master">    <type></type>    <title>{en:Sort ID;zh:分类代?雧</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter>50100000</filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="taskname" owner="master">    <type></type>    <title>{en:Task Name;zh:任务名称}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>50</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="items" owner="master">    <type></type>    <title>{en:Task List;zh:任务列表}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="tasktype" owner="master">    <type></type>    <title>{en:Time Type;zh:时间类型}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="devtype" owner="master">    <type></type>    <title>{en:Device Type;zh:设备类型}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="quality" owner="master">    <type></type>    <title>{en:Quality;zh:声音品质}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="state" owner="master">    <type></type>    <title>{en:State;zh:状态}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="weekmark" owner="master">    <type></type>    <title>{en:Weekly Task;zh:每周任务}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="monthmark" owner="master">    <type></type>    <title>{en:Monthly Task;zh:每月任务}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="datestart" owner="master">    <type></type>    <title>{en:Start Date;zh:开始日期}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="dateend" owner="master">    <type></type>    <title>{en:End Date;zh:结束日期}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="timestart" owner="master">    <type></type>    <title>{en:Start Time;zh:开始时间}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="timeend" owner="master">    <type></type>    <title>{en:End Time;zh:结束时间}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="recflag" owner="master">    <type></type>    <title>{en:Flag;zh:记录标识}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="priority" owner="master">    <type></type>    <title>Priority</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="enabled" owner="master">    <type></type>    <title>Enabled</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>  </fieldx>  ', null, null, null, null, '', 'AsrFlag=dict:Enabled,   TaskType=dict:timetype,    RecFlag=dict:taskflag', null, '', null, 'taskid=Task ID, TaskName=Task Name,   TaskType=任务类型,  DevType=设备类型', 'select m.taskid, m.TaskName, m.TaskType, m.DevType, m.DateStart, m.DateEnd, m.TimeStart, m.TimeEnd, m.AsrPercent, m.AsrPkgs, m.RecFlag, m.AsrFlag, m.Enabled from vxi_rec..task m', 'select m.taskid, m.SortId, m.TaskName, m.Items, m.TaskType, m.DevType, m.Quality, m.State, m.WeekMark, m.MonthMark, m.DateStart, m.DateEnd, m.TimeStart, m.TimeEnd, m.RecFlag, m.Priority, m.AsrPercent, m.AsrPkgs, m.AsrFlag, m.Enabled, m.recstorage, m.scrstorage from vxi_rec..task m where m.taskid = !taskid', 'select m.taskid, m.SortId, m.TaskName, m.Items, m.TaskType, m.DevType, m.Quality, m.State, m.WeekMark, m.MonthMark, m.DateStart, m.DateEnd, m.TimeStart, m.TimeEnd, m.RecFlag, m.Priority, m.AsrPercent, m.AsrPkgs, m.AsrFlag, m.Enabled, m.recstorage, m.scrstorage, m.RecPercent,m.ScrPercent from vxi_rec..task m where m.taskid = !taskid', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rec.total.stat', '{zh:总体录音统计报表,en:Recording Statistic Report}', 100, '', 50500000, 44, 1, 15, 15, -1, '', '', null, null, null, '', '', null, null, '', '', '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_record_ext_report @GroupByExt=0,@Language=!language,@SplitTm=60,@stat=1,@GroupByPrj=0', '', '', '', '', '', '', '', '', '', '', '', '', '', '', null, null, null, null, 'date_group', null, null, null, null, null, null, null, null, null, null, null, 'prjid,extensions,TimeFrame=Time:PeriodTime', null, null, null, null, null, null, null, 'DateSch=RepDate, rec_n=rec_n', null, null, null, null, null, null, null, null, null, null, '1', '1', '', '', '', null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rec.words', '{zh:词管理, en:Word Manage}', 100, '', 20700000, 17, 7, 15, 15, -1, 'vxi_rec.asr.words', 'WordID', 1, 1, null, 'vxi_rec.asr.word', 'LogId', 1, 1, '', '', '', 1000, 0, 'ext.search.jsp', '', '', 'rec.words.jsp', 'rec.words.jsp', '', '', '', '', 'ext.search.jsp', 'rec.words.item.jsp', 'rec.words.item.jsp', '', '', '', '', null, '', '', '', '', '', 'syn=dict:wordid', 'syn=dict:wordid', 'syn=dict:wordid', '', '', '', '', '', '', '', '', '', '', '', '', '', '', null, null, null, null, null, 'WordID={zh:词编号; en:WordID},  Decription={zh:描述; en:Description},  Enabled={zh:状态; en:Status},  LogId={zh:明细编号; en:ItemId},  Word={zh:词; en:Word}  ', null, null, null, null, null, null, null, null, null, null, 'WordID=WordID', 'select m.WordID, m.decription, m.enabled from vxi_rec.asr.words m', 'select m.WordID, m.Decription, m.Enabled from vxi_rec.asr.words m where m.WordID = !WordID', 'select m.WordID, m.Decription, m.Enabled from vxi_rec.asr.words m where m.WordID = !WordID', null, null, null, 'Word=Word', null, 'select m.WordID, s.Word, s.LogId from vxi_rec.asr.words m inner join vxi_rec.asr.word s on m.WordID = s.WordID', 'select m.WordID, s.LogId, s.Word from vxi_rec.asr.words m inner join vxi_rec.asr.word s on m.WordID = s.WordID where m.WordID = !WordID order by s.Word', 'select m.WordID, s.Word, s.Enabled from vxi_rec.asr.words m inner join vxi_rec.asr.word s on m.WordID = s.WordID where m.WordID = !WordID and s.LogId = !LogId', 'select m.WordID, s.Word, s.Enabled from vxi_rec.asr.words m inner join vxi_rec.asr.word s on m.WordID = s.WordID where m.WordID = !WordID and s.LogId = !LogId', null, null, null, null, null, 1, '', '', '', null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('requirement', '{zh:需求日志管理, en:Requirement Log}', 100, '', 60300000, 79, 15, 15, 15, 62349, 'vxi_req..Requirement', 'ReqId', 1, 1, null, '', '', null, null, '', null, '', 1000, 0, 'ext.search.jsp', 'calendar.jsp', 'schcombox.jsp', 'requirement.jsp', 'requirement.jsp', 'requirement.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'ReqId={zh:代码;en:Req ID}, PrjId={zh:项目;en:Porject}, ReqDate={zh:日期;en:Date}, Requirement={zh:需求内容;en:Requirement}, Detail={zh:详细描述;en:Detail}, Sender={zh:提供方;en:Sender}, Receiver={zh:接收方;en:Receiver}, ReqType={zh:类型;en:Req Type}, Difficulty={zh:难度;en:Difficulty}, Precept={zh:解决预案;en:Precept}, Solution={zh:解决方案;en:Solution}, Process={zh:处理状态;en:Process}, ProcDate={zh:处理日期;en:Process Date}, Note={zh:备注;en:Note}, Enabled={zh:有效标志;en:Enabled}', '<fieldx>   <field name="reqid" owner="master">    <type>auto</type>    <title>{zh:代码;en:Req ID}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey>yes</tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="prjid" owner="master">    <type></type>    <title>{zh:项目;en:Porject}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="reqdate" owner="master">    <type>date</type>    <title>{zh:日期;en:Date}</title>    <dict></dict>    <format>yyyy-MM-dd</format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="requirement" owner="master">    <type></type>    <title>{zh:需求内容;en:Requirement}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>500</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="detail" owner="master">    <type></type>    <title>{zh:详细描述;en:Detail}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>2000</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="sender" owner="master">    <type></type>    <title>{zh:提供方;en:Sender}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>100</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="receiver" owner="master">    <type></type>    <title>{zh:接收方;en:Receiver}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>100</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="reqtype" owner="master">    <type></type>    <title>{zh:类型;en:Req Type}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>50</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="difficulty" owner="master">    <type>image</type>    <title>{zh:难度;en:Difficulty}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images>low=style/vxistyle/css/xtheme-slate/images/slate/window/icon-info.gif, middle=style/vxistyle/css/xtheme-slate/images/slate/window/icon-warning.gif, high=style/vxistyle/css/xtheme-slate/images/slate/window/icon-error.gif</images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="precept" owner="master">    <type></type>    <title>{zh:解决预案;en:Precept}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>2000</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="solution" owner="master">    <type></type>    <title>{zh:解决方案;en:Solution}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>2000</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="process" owner="master">    <type></type>    <title>{zh:处理状态;en:Process}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="procdate" owner="master">    <type></type>    <title>{zh:处理日期;en:Process Date}</title>    <dict></dict>    <format>yyyy-MM-dd</format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="note" owner="master">    <type></type>    <title>{zh:备注;en:Note}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>2000</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="acked" owner="master">    <type></type>    <title>Acked</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="enabled" owner="master">    <type></type>    <title>{zh:有效标志;en:Enabled}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>  </fieldx>  ', null, null, null, null, '', 'ProcDate=date, ReqDate=date', null, '', null, 'ReqId={zh:需求代码;en:ReqId},Requirement={zh:需求内容;en:Requirement}, Detail={zh:详细描述;en:Detail}, Sender={zh:提供方;en:Sender}, Receiver={zh:接收方;en:Receiver}, ReqType={zh:类型;en:Req Type}, Difficulty={zh:难度;en:Difficulty}, Precept={zh:解决预案;en:Precept}, Solution={zh:解决方案;en:Solution}, Process={zh:处理状态;en:Process}, ProcDate={zh:处理日期;en:Process Date}, Note={zh:备注;en:Note}, DateRange=ReqDate', 'select m.ReqId, m.ReqDate, m.Requirement, m.ReqType, m.Difficulty, m.Process from vxi_req..Requirement m order by m.ReqId desc', 'select m.ReqId, m.PrjId, m.ReqDate, m.Requirement, m.Detail, m.Sender, m.Receiver, m.ReqType, m.Difficulty, m.Precept, m.Solution, m.Process, m.ProcDate, m.Note, m.Acked, m.Enabled from vxi_req..Requirement m where m.ReqId = !ReqId', 'select m.ReqId, m.PrjId, m.ReqDate, m.Requirement, m.Detail, m.Sender, m.Receiver, m.ReqType, m.Difficulty, m.Precept, m.Solution, m.Process, m.ProcDate, m.Note, m.Acked, m.Enabled from vxi_req..Requirement m where m.ReqId = !ReqId', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 0, null, null, null, null, null, null, null, null, null, null, null, null, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('roles', '{zh:操作员角色定义, en:User Role Setting}', 100, '0', 10200000, 2, 7, 15, 15, -1, 'roles', 'role', 1, 1, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.skip.search.jsp', null, null, 'roles.jsp', 'roles.jsp', '', '', '', '', '', '', '', '', '', null, null, '', '', '', null, '', '', 'syn=dict', 'syn=dict', 'syn=dict', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', '', null, 'role={en:Role;zh:角色},   rolename={en:Name;zh:角色名称},   summary={en:Description;zh:描述},   privilege={en:Privilege;zh:权限},   acked={en:Acked;zh:确认标志}', null, null, null, null, null, '', '', null, '', null, 'role=Role ID, rolename=Role Name', 'select m.role, m.rolename, m.privilege, m.enabled from roles m', 'select m.* from roles m where m.role = !role', 'select m.role, m.rolename, m.privilege, m.summary, m.enabled from roles m where m.role = !role', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('route', '{zh:路由设备定义, en:Route Device Setting}', 100, '0', 20100000, 11, 7, 15, 15, 16777215, 'vxi_sys..route', 'Route', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, 'ext.edit.search.jsp', '', '', 'route.jsp', 'route.jsp', 'route.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'syn=dict:route  send=VisionIRS  send=VisionCTI  send=VisionEMS  send=VisionLog', 'syn=dict:route  send=VisionIRS  send=VisionCTI  send=VisionEMS  send=VisionLog', 'syn=dict:route  send=VisionIRS  send=VisionCTI  send=VisionEMS  send=VisionLog', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', 'sortid=20100000', '', 'Route={en:Route ID; zh:路由设备}, RouteName={en:Route Name; zh:路由设备名称}, Sort={en:Sort; zh:分类}, SortId={en:Sort ID; zh:分类代码}, SwitchIn={en:Access No.; zh:电话接入号}, Station={en:Route Server; zh:关联服务器}', null, null, null, null, null, '', '', null, '', null, 'Route=Route ID, RouteName=Route Name, SwitchIn=Access No.', 'select m.Route, m.RouteName, m.SwitchIn, m.Station, m.Enabled from vxi_sys..Route m left join sort t on m.sortid = t.sortid', 'select m.Route, m.RouteName, m.SortId, m.SwitchIn, m.Station, m.Enabled from vxi_sys..Route m where m.Route = !Route', 'select m.Route, m.RouteName, m.SortId, m.SwitchIn, m.Station, m.Enabled from vxi_sys..Route m where m.Route = !Route', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('service', '{zh:服务程序设置, en:Service Setting}', 100, '0', 10300000, 3, 7, 15, 15, -1, 'vxi_def..service', 'Service', 0, 0, null, null, null, null, null, null, null, null, 1000, 0, 'ext.search.jsp', null, null, 'service.jsp', 'service.jsp', '', '', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'Service={en:Service;zh:服务名称},  Host={en:Host;zh:主机IP},  Port={en:Service Port;zh:服务端口},  SvcType={en:Service Type;zh:服务类型},  Context={en:Context;zh:上下文},  ClsName={zh:类名称; en:Class Name},  Enabled={zh:状态; en:Status}', '<fieldx>   <field name="service" owner="master">    <type></type>    <title>{en:Service;zh:服务名称}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey>yes</tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="host" owner="master">    <type></type>    <title>{en:Host;zh:主机IP}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>32</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="port" owner="master">    <type></type>    <title>{en:Service Port;zh:服务端口}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="svctype" owner="master">    <type></type>    <title>{en:Service Type;zh:服务类型}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="context" owner="master">    <type></type>    <title>{en:Corba Context;zh:Corba环境}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>50</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>     <field name="enabled" owner="master">    <type></type>    <title>{en:Status;zh:状态}</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>  </fieldx>  ', null, null, null, null, null, null, null, null, null, 'service, Host, Port, SvcType, Context, Enabled, ClsName', 'select m.service, m.Host, m.Port, m.SvcType, m.ClsName, m.Context, m.Enabled from service m', 'select m.service, m.ClsName, m.Host, m.Port, m.SvcType, m.Context, m.ActFlag, m.Enabled from service m where m.service = !service', 'select m.service, m.ClsName, m.Host, m.Port, m.SvcType, m.Context, m.ActFlag, m.Enabled from service m where m.service = !service', null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, 1, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('service.start.control', '{en:Service Start Control, zh:服务启动控制}', 100, null, 10300000, 90, 1, 15, 15, -1, 'dblink', 'dblink', 0, 0, null, null, null, null, null, null, null, null, 1000, 0, 'ext.skip.search.jsp', '', '', null, 'ext.service.start.control.jsp', '', '', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'dblink, Host, LogUser', 'select m.dblink, m.Host, m.LogUser, m.DbType, m.SplitKey, m.ActFlag from dblink m', 'select m.dblink, m.Host, m.LogUser, m.LogPass, m.DbType, m.SplitKey, m.SplitValue, m.Summary, m.ActFlag, m.Enabled from dblink m where m.dblink = !dblink', 'select m.dblink, m.Host, m.LogUser, m.LogPass, m.DbType, m.SplitKey, m.SplitValue, m.Summary, m.ActFlag, m.Enabled from dblink m where m.dblink = !dblink', null, null, null, null, 'select isnull(max(sampid), 1) maxid from wfm_biz..WorkForceSample', null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('skill', '{zh:技能组定义, en:Skill Group Setting}', 100, '0', 20100000, 11, 7, 15, 15, -1, 'vxi_sys..Skill', 'skill', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, 'ext.edit.search.jsp', '', '', 'skill.jsp', 'skill.jsp', 'skill.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'syn=dict  send=VisionCTI  send=VisionEMS  send=VisionLog', 'syn=dict  send=VisionCTI  send=VisionEMS  send=VisionLog', 'syn=dict  send=VisionCTI  send=VisionEMS  send=VisionLog', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', 'sortid=20100000', '', 'Skill={en:Skill/ACD; zh:技能组}, Sort={en:Sort; zh:分类}, SkillName={en:Skill Name; zh:技能组名称}, Enabled={en:Status; zh:状态}', null, null, null, null, null, '', '', null, '', null, 'Skill=Skill/ACD, Sort=Sort, SkillName=Skill Name', 'select m.Skill,  m.SkillName, m.SkillType, m.Enabled from vxi_sys..Skill m left join sort t on m.sortid = t.sortid', 'select m.Skill, SortId, SkillName, Summary, SkillType, Enabled from vxi_sys..Skill m where m.Skill = !Skill', 'select m.Skill, SortId, SkillName, Summary, SkillType, Enabled from vxi_sys..Skill m where m.Skill = !Skill', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('softph.admin', '{zh:管理座席软电话, en:Admin Agent Softphone}', 100, '0', 30100000, 31, 1, 15, 15, -1, '', 'agent', 0, 0, null, '', '', null, null, '', null, '', 1000, 0, 'softph_admin.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', 'display_btns=true', '', '', null, null, null, null, null, '', '', null, '', null, '', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('softph.view', '{zh:座席实时状态查询, en:Agent Status Real Time Monitor}', 100, '0', 30100000, 31, 1, 15, 15, -1, '', 'agent', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, 'softph_admin.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', 'display_btns=false', '', '', null, null, null, null, null, '', '', null, '', null, '', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('sort', '{zh:系统分类定义, en:Sort Setting}', 100, '0', 10100000, 2, 15, 15, 15, -1, 'sort', 'sortid', 1, 0, null, '', '', 0, 0, '', null, 'SortInit.jsp', 1000, 0, 'ext.edit.search.jsp', '', 'schcombox.jsp', 'sort.jsp', 'sort.jsp', '', '', '', '', '', '', '', '', 'sp_sort_insert @parent_id = !parent_id, @sort = !sort', '', null, '', '', '', null, '', '', 'syn=sort  syn=dict:sortid', 'syn=sort  syn=dict:sortid', 'syn=sort  syn=dict:sortid', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'sortid={zh:分类代码;en:Sort ID},   Sort={zh:分类名称;en:Sort Name},   RootUrl={zh:分类链接;en:Sort Link},   HtmlFile={zh:模板文件;en:Template File},   Summary={zh:分类描述;en:Summary},   Enabled={zh:有效标志;en:Enabled},   Sort01={zh:一层;en: Sort01},   Sort02={zh:二层;en: Sort02},   Sort03={zh:三层;en: Sort03},   Sort04={zh:四层;en: Sort04},   Sort05={zh:五层;en: Sort05},   Sort06={zh:六层;en: Sort06}', null, null, null, null, null, '', '', null, '', null, 'sortid=分类代码, Sort=分类名称, RootUrl=分类链接, HtmlFile=模板文件', 'select m.sortid, m.Sort, m.Sort01, m.Sort02, m.Sort03, m.Sort04, m.Sort05, m.Sort06, m.RootUrl, m.HtmlFile, m.enabled from sort m order by m.sortid', 'select m.sortid, m.Sort, m.Sort01, m.Sort02, m.Sort03, m.Sort04, m.Sort05, m.Sort06, m.RootUrl, m.HtmlFile, m.Summary, m.Leaf, m.Acked, m.Enabled, m.iconCls from sort m where m.sortid = !sortid', 'select m.sortid, m.Sort, m.RootUrl, m.HtmlFile, m.Summary, m.Enabled, m.iconCls from sort m where m.sortid = !sortid', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.agent.report.day', '{zh:座席状态统计报表(日报),en:Agent Statistic Report (Daily)}', 100, '', 30302000, 23, 1, 15, 15, -1, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_agent_report', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'prjid={en:Project ID;zh:项目},  date_group={en:Group Level;zh:分组类别},  RecDT={en:RecDT;zh:日期},  Agent={en:Agent;zh:座席},  FirstLogin={en:First Login;zh:最早登录时间},  LastLogout={en:Last Logout;zh:最晚登出时间},  Login={en:Login;zh:登录次数},  LoginTime={en:Login Time;zh:登录时长},  Ready={en:Ready;zh:就绪次数},  ReadyTime={en:Ready Time;zh:就绪时长},  Acw={en:Acw;zh:话后工作次数},  AcwTime={en:Acw Time;zh:话后工作时长},  TalkTime={en:Talk Time;zh:通话时长},  IdleTime={en:Idle Time;zh:空闲时长},  NotReady00={en:Not Ready 00;zh:置忙状态次数00},  NotReady01={en:Not Ready 01;zh:置忙状态次数01},  NotReady02={en:Not Ready 02;zh:置忙状态次数02},  NotReady03={en:Not Ready 03;zh:置忙状态次数03},  NotReady04={en:Not Ready 04;zh:置忙状态次数04},  NotReady05={en:Not Ready 05;zh:置忙状态次数05},  NotReady06={en:Not Ready 06;zh:置忙状态次数06},  NotReady07={en:Not Ready 07;zh:置忙状态次数07},  NotReady08={en:Not Ready 08;zh:置忙状态次数08},  NotReady09={en:Not Ready 09;zh:置忙状态次数09},  NotReady00Time={en:NotReady 00 Time;zh:置忙状态时长00},  NotReady01Time={en:NotReady 01 Time;zh:置忙状态时长01},  NotReady02Time={en:NotReady 02 Time;zh:置忙状态时长02},  NotReady03Time={en:NotReady 03 Time;zh:置忙状态时长03},  NotReady04Time={en:NotReady 04 Time;zh:置忙状态时长04},  NotReady05Time={en:NotReady 05 Time;zh:置忙状态时长05},  NotReady06Time={en:NotReady 06 Time;zh:置忙状态时长06},  NotReady07Time={en:NotReady 07 Time;zh:置忙状态时长07},  NotReady08Time={en:NotReady 08 Time;zh:置忙状态时长08},  NotReady09Time={en:NotReady 09 Time;zh:置忙状态时长09},  Logout00={en:Logout 00;zh:登出次数00},  Logout01={en:Logout 01;zh:登出次数01},  Logout02={en:Logout 02;zh:登出次数02},  Logout03={en:Logout 03;zh:登出次数03},  Logout04={en:Logout 04;zh:登出次数04},  Logout05={en:Logout 05;zh:登出次数05},  Logout06={en:Logout 06;zh:登出次数06},  Logout07={en:Logout 07;zh:登出次数07},  Logout08={en:Logout 08;zh:登出次数08},  Logout09={en:Logout 09;zh:登出次数09},  Logout00Time={en:Logout00 Time;zh:登出时长00},  Logout01Time={en:Logout01 Time;zh:登出时长01},  Logout02Time={en:Logout02 Time;zh:登出时长02},  Logout03Time={en:Logout03 Time;zh:登出时长03},  Logout04Time={en:Logout04 Time;zh:登出时长04},  Logout05Time={en:Logout05 Time;zh:登出时长05},  Logout06Time={en:Logout06 Time;zh:登出时长06},  Logout07Time={en:Logout07 Time;zh:登出时长07},  Logout08Time={en:Logout08 Time;zh:登出时长08},  Logout09Time={en:Logout09Time;zh:登出时长09},  RepDate={en:Report Date;zh:报表日期}', null, '', '', '', '', '', 'LoginTime=time_sec,  ReadyTime=time_sec, AcwTime=time_sec,  TalkTime=time_sec,  IdleTime=time_sec,  NotReady00Time=time_sec, NotReady01Time=time_sec,  NotReady02Time=time_sec,  NotReady03Time=time_sec,  NotReady04Time=time_sec,  NotReady05Time=time_sec, NotReady06Time=time_sec,  NotReady07Time=time_sec,  NotReady08Time=time_sec, NotReady09Time=time_sec, Logout00Time=time_sec,  Logout01Time=time_sec, Logout02Time=time_sec, Logout03Time=time_sec, Logout04Time=time_sec, Logout05Time=time_sec, Logout06Time=time_sec, Logout07Time=time_sec, Logout08Time=time_sec, Logout09Time=time_sec', '', '', '', 'DateSch=RepDate,  PrjId=Project ID,  Agent=Agent', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.agent.report.month', '{zh:座席状态统计报表(月报),en:Agent Statistic Report (Monthly)}', 100, '0', 30302000, 23, 1, 15, 15, -1, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_agent_report', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'prjid={en:Project ID;zh:项目},  date_group={en:Group Level;zh:分组类别},  RecDT={en:RecDT;zh:日期},  Agent={en:Agent;zh:座席},  FirstLogin={en:First Login;zh:最早登录时间},  LastLogout={en:Last Logout;zh:最晚登出时间},  Login={en:Login;zh:登录次数},  LoginTime={en:Login Time;zh:登录时长},  Ready={en:Ready;zh:就绪次数},  ReadyTime={en:Ready Time;zh:就绪时长},  Acw={en:Acw;zh:话后工作次数},  AcwTime={en:Acw Time;zh:话后工作时长},  TalkTime={en:Talk Time;zh:通话时长},  IdleTime={en:Idle Time;zh:空闲时长},  NotReady00={en:Not Ready 00;zh:置忙状态次数00},  NotReady01={en:Not Ready 01;zh:置忙状态次数01},  NotReady02={en:Not Ready 02;zh:置忙状态次数02},  NotReady03={en:Not Ready 03;zh:置忙状态次数03},  NotReady04={en:Not Ready 04;zh:置忙状态次数04},  NotReady05={en:Not Ready 05;zh:置忙状态次数05},  NotReady06={en:Not Ready 06;zh:置忙状态次数06},  NotReady07={en:Not Ready 07;zh:置忙状态次数07},  NotReady08={en:Not Ready 08;zh:置忙状态次数08},  NotReady09={en:Not Ready 09;zh:置忙状态次数09},  NotReady00Time={en:NotReady 00 Time;zh:置忙状态时长00},  NotReady01Time={en:NotReady 01 Time;zh:置忙状态时长01},  NotReady02Time={en:NotReady 02 Time;zh:置忙状态时长02},  NotReady03Time={en:NotReady 03 Time;zh:置忙状态时长03},  NotReady04Time={en:NotReady 04 Time;zh:置忙状态时长04},  NotReady05Time={en:NotReady 05 Time;zh:置忙状态时长05},  NotReady06Time={en:NotReady 06 Time;zh:置忙状态时长06},  NotReady07Time={en:NotReady 07 Time;zh:置忙状态时长07},  NotReady08Time={en:NotReady 08 Time;zh:置忙状态时长08},  NotReady09Time={en:NotReady 09 Time;zh:置忙状态时长09},  Logout00={en:Logout 00;zh:登出次数00},  Logout01={en:Logout 01;zh:登出次数01},  Logout02={en:Logout 02;zh:登出次数02},  Logout03={en:Logout 03;zh:登出次数03},  Logout04={en:Logout 04;zh:登出次数04},  Logout05={en:Logout 05;zh:登出次数05},  Logout06={en:Logout 06;zh:登出次数06},  Logout07={en:Logout 07;zh:登出次数07},  Logout08={en:Logout 08;zh:登出次数08},  Logout09={en:Logout 09;zh:登出次数09},  Logout00Time={en:Logout00 Time;zh:登出时长00},  Logout01Time={en:Logout01 Time;zh:登出时长01},  Logout02Time={en:Logout02 Time;zh:登出时长02},  Logout03Time={en:Logout03 Time;zh:登出时长03},  Logout04Time={en:Logout04 Time;zh:登出时长04},  Logout05Time={en:Logout05 Time;zh:登出时长05},  Logout06Time={en:Logout06 Time;zh:登出时长06},  Logout07Time={en:Logout07 Time;zh:登出时长07},  Logout08Time={en:Logout08 Time;zh:登出时长08},  Logout09Time={en:Logout09Time;zh:登出时长09},  RepDate={en:Report Date;zh:报表日期}', null, '', '', '', '', '', 'LoginTime=time_sec,  ReadyTime=time_sec, AcwTime=time_sec,  TalkTime=time_sec,  IdleTime=time_sec,  NotReady00Time=time_sec, NotReady01Time=time_sec,  NotReady02Time=time_sec,  NotReady03Time=time_sec,  NotReady04Time=time_sec,  NotReady05Time=time_sec, NotReady06Time=time_sec,  NotReady07Time=time_sec,  NotReady08Time=time_sec, NotReady09Time=time_sec, Logout00Time=time_sec,  Logout01Time=time_sec, Logout02Time=time_sec, Logout03Time=time_sec, Logout04Time=time_sec, Logout05Time=time_sec, Logout06Time=time_sec, Logout07Time=time_sec, Logout08Time=time_sec, Logout09Time=time_sec', '', '', '', 'MonthSch=RepDate,  PrjId=Project ID,  Agent=Agent', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.agent.stat', '{zh:坐席状态时长分布,en:Agent Status Time Long Distribute}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_dist_agent_status @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,Skill,begtime=TimeBegin,endtime=TimeEnd,SkillGroup,groupid,agent  ', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.agent.stat.sample', '{zh:坐席状态实时采样统计,en:Agetn Status Real Time Sample}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_stat_agent_sample @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,Skill,begtime=TimeBegin,endtime=TimeEnd,SkillGroup,groupid', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.agent.status.stat', '{zh:坐席状态统计,en:Agent Status Statistics}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_stat_agent_status @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,agent,begdate=DateBegin,enddate=DateEnd,Skill,SkillGroup,begtime=TimeBegin,endtime=TimeEnd,groupid=AgentGroupId,period=GroupLevel', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.agent.timing.sample', '{zh:坐席状态时序采样统计,en:Agent Status Time Series Sample}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_stat_agent_timing_sample @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,Skill,begtime=TimeBegin,endtime=TimeEnd,SkillGroup,groupid', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.aux.analysis', '{zh:AUX分析,en:AUX Analysis}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.kpi.sp_aux_analysis @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,Skill,SkillGroup,groupid,period=GroupLevel', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.agent.report.range', '{zh:座席状态统计报表,en:Agent Statistic Report (Range)}', 100, '0', 30302000, 23, 1, 15, 15, 4194303, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 3000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_agent_report', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'prjid={en:Project ID;zh:项目},  date_group={en:Group Level;zh:分组类别},  RecDT={en:RecDT;zh:日期},  Agent={en:Agent;zh:座席},  FirstLogin={en:First Login;zh:最早登录时间},  LastLogout={en:Last Logout;zh:最晚登出时间},  Login={en:Login;zh:登录次数},  LoginTime={en:Login Time;zh:登录时长},  Ready={en:Ready;zh:就绪次数},  ReadyTime={en:Ready Time;zh:就绪时长},  Acw={en:Acw;zh:话后工作次数},  AcwTime={en:Acw Time;zh:话后工作时长},  TalkTime={en:Talk Time;zh:通话时长},  IdleTime={en:Idle Time;zh:空闲时长},  NotReady00={en:Not Ready 00;zh:置忙状态次数00},  NotReady01={en:Not Ready 01;zh:置忙状态次数01},  NotReady02={en:Not Ready 02;zh:置忙状态次数02},  NotReady03={en:Not Ready 03;zh:置忙状态次数03},  NotReady04={en:Not Ready 04;zh:置忙状态次数04},  NotReady05={en:Not Ready 05;zh:置忙状态次数05},  NotReady06={en:Not Ready 06;zh:置忙状态次数06},  NotReady07={en:Not Ready 07;zh:置忙状态次数07},  NotReady08={en:Not Ready 08;zh:置忙状态次数08},  NotReady09={en:Not Ready 09;zh:置忙状态次数09},  NotReady00Time={en:NotReady 00 Time;zh:置忙状态时长00},  NotReady01Time={en:NotReady 01 Time;zh:置忙状态时长01},  NotReady02Time={en:NotReady 02 Time;zh:置忙状态时长02},  NotReady03Time={en:NotReady 03 Time;zh:置忙状态时长03},  NotReady04Time={en:NotReady 04 Time;zh:置忙状态时长04},  NotReady05Time={en:NotReady 05 Time;zh:置忙状态时长05},  NotReady06Time={en:NotReady 06 Time;zh:置忙状态时长06},  NotReady07Time={en:NotReady 07 Time;zh:置忙状态时长07},  NotReady08Time={en:NotReady 08 Time;zh:置忙状态时长08},  NotReady09Time={en:NotReady 09 Time;zh:置忙状态时长09},  Logout00={en:Logout 00;zh:登出次数00},  Logout01={en:Logout 01;zh:登出次数01},  Logout02={en:Logout 02;zh:登出次数02},  Logout03={en:Logout 03;zh:登出次数03},  Logout04={en:Logout 04;zh:登出次数04},  Logout05={en:Logout 05;zh:登出次数05},  Logout06={en:Logout 06;zh:登出次数06},  Logout07={en:Logout 07;zh:登出次数07},  Logout08={en:Logout 08;zh:登出次数08},  Logout09={en:Logout 09;zh:登出次数09},  Logout00Time={en:Logout00 Time;zh:登出时长00},  Logout01Time={en:Logout01 Time;zh:登出时长01},  Logout02Time={en:Logout02 Time;zh:登出时长02},  Logout03Time={en:Logout03 Time;zh:登出时长03},  Logout04Time={en:Logout04 Time;zh:登出时长04},  Logout05Time={en:Logout05 Time;zh:登出时长05},  Logout06Time={en:Logout06 Time;zh:登出时长06},  Logout07Time={en:Logout07 Time;zh:登出时长07},  Logout08Time={en:Logout08 Time;zh:登出时长08},  Logout09Time={en:Logout09Time;zh:登出时长09},  RepDate={en:Report Date;zh:报表日期}', null, '', '', '', '', '', 'LoginTime=time_sec,  ReadyTime=time_sec, AcwTime=time_sec,  TalkTime=time_sec,  IdleTime=time_sec,  NotReady00Time=time_sec, NotReady01Time=time_sec,  NotReady02Time=time_sec,  NotReady03Time=time_sec,  NotReady04Time=time_sec,  NotReady05Time=time_sec, NotReady06Time=time_sec,  NotReady07Time=time_sec,  NotReady08Time=time_sec, NotReady09Time=time_sec, Logout00Time=time_sec,  Logout01Time=time_sec, Logout02Time=time_sec, Logout03Time=time_sec, Logout04Time=time_sec, Logout05Time=time_sec, Logout06Time=time_sec, Logout07Time=time_sec, Logout08Time=time_sec, Logout09Time=time_sec', '', '', '', 'TimeRange=Time,  PrjId=Project ID,  Agent=Agent', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.avg.ansvol', '{zh:人均接听量,en:Average Answered}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.kpi.sp_stat_avg_ansvol @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'projectid,begdate=DateBegin,enddate=DateEnd,period=GroupLevel,begtime=TimeBegin,endtime=TimeEnd,schkeyname=schkey', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.call.abandon.stat', '{zh:放弃电话统计,en:Missed Call Statistics}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_stat_call_abandon @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'projectid,begdate=DateBegin,enddate=DateEnd,period=group_level,begtime=TimeBegin,endtime=TimeEnd,schkeyname=sch_key', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.call.agent.abandon.stat', '{zh:坐席放弃电话统计,en:Agent Missed Call Statistics}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_dist_call_agent  @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,Skill,SkillGroup,begdate=DateBegin,enddate=DateEnd,groupid=GroupId,begtime=TimeBegin,endtime=TimeEnd,agent', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.call.agent.anwerd.dist', '{zh:坐席电话接听量分布,en:Agent Answered Distribute}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_dist_call_agent_answerd @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,Skill,begtime=TimeBegin,endtime=TimeEnd,SkillGroup,groupid=GroupId,agent', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.call.agent.stat', '{zh:坐席呼叫统计,en:Agent Call Statistics}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_stat_agent_call @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,agent,begdate=DateBegin,enddate=DateEnd,Skill,SkillGroup,begtime=TimeBegin,endtime=TimeEnd,groupid=AgentGroupId,period=GroupLevel', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.call.answerd.dist', '{zh:电话应答分布,en:Answered Call Distribution}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_dist_call_answerd @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,Skill,begtime=TimeBegin,endtime=TimeEnd,groupid,agent,devtype=devtypename', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.call.full.record', '{zh:呼叫完整记录,en:Complete Call Record}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_sch_call_detail @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,Skill,SkillGroup,begtime=TimeBegin,endtime=TimeEnd,groupid=GroupId,Agent,  calltype=type  ', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.call.in.record', '{zh:呼入详细记录,en: Detailed Inbound Record}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_sch_call_inbound  @type=1,@preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,Skill,begtime=TimeBegin,endtime=TimeEnd,SkillGroup,groupid,Agent', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.call.out.record', '{zh:呼出详细记录,en:Detailed Outbound Record}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, '', null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_sch_call_outbound  @type=2,@preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,Skill,begtime=TimeBegin,endtime=TimeEnd,SkillGroup,groupid=AgentGroupId,Agent', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.call.out.stat', '{zh:呼出电话统计,en:Outbound Statistics}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, 1, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_stat_call_outbound  @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'projectid,begdate=DateBegin,enddate=DateEnd=,period=group_level,begtime=TimeBegin,endtime=TimeEnd,schkeyname=sch_key', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.call.source.dist', '{zh:坐席电话来源分布,en:Agent Call Source Distribute}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_dist_call_source @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,period=GroupLevel,begdate=DateBegin,enddate=DateEnd,Skill,SkillGroup,begtime=TimeBegin,endtime=TimeEnd,groupid=GroupId,agent', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.call.stat', '{zh:呼叫统计,en:Call Statistics}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_sch_call_report @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,period=group_level,begtime=TimeBegin,endtime=TimeEnd,schkeyname=sch_key', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.agent.report.year', '{zh:座席状态统计报表(年报), en:Agent Statistic Report (Annually)}', 100, '0', 30302000, 23, 1, 15, 15, -1, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_agent_report', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'prjid={en:Project ID;zh:项目},  date_group={en:Group Level;zh:分组类别},  RecDT={en:RecDT;zh:日期},  Agent={en:Agent;zh:座席},  FirstLogin={en:First Login;zh:最早登录时间},  LastLogout={en:Last Logout;zh:最晚登出时间},  Login={en:Login;zh:登录次数},  LoginTime={en:Login Time;zh:登录时长},  Ready={en:Ready;zh:就绪次数},  ReadyTime={en:Ready Time;zh:就绪时长},  Acw={en:Acw;zh:话后工作次数},  AcwTime={en:Acw Time;zh:话后工作时长},  TalkTime={en:Talk Time;zh:通话时长},  IdleTime={en:Idle Time;zh:空闲时长},  NotReady00={en:Not Ready 00;zh:置忙状态次数00},  NotReady01={en:Not Ready 01;zh:置忙状态次数01},  NotReady02={en:Not Ready 02;zh:置忙状态次数02},  NotReady03={en:Not Ready 03;zh:置忙状态次数03},  NotReady04={en:Not Ready 04;zh:置忙状态次数04},  NotReady05={en:Not Ready 05;zh:置忙状态次数05},  NotReady06={en:Not Ready 06;zh:置忙状态次数06},  NotReady07={en:Not Ready 07;zh:置忙状态次数07},  NotReady08={en:Not Ready 08;zh:置忙状态次数08},  NotReady09={en:Not Ready 09;zh:置忙状态次数09},  NotReady00Time={en:NotReady 00 Time;zh:置忙状态时长00},  NotReady01Time={en:NotReady 01 Time;zh:置忙状态时长01},  NotReady02Time={en:NotReady 02 Time;zh:置忙状态时长02},  NotReady03Time={en:NotReady 03 Time;zh:置忙状态时长03},  NotReady04Time={en:NotReady 04 Time;zh:置忙状态时长04},  NotReady05Time={en:NotReady 05 Time;zh:置忙状态时长05},  NotReady06Time={en:NotReady 06 Time;zh:置忙状态时长06},  NotReady07Time={en:NotReady 07 Time;zh:置忙状态时长07},  NotReady08Time={en:NotReady 08 Time;zh:置忙状态时长08},  NotReady09Time={en:NotReady 09 Time;zh:置忙状态时长09},  Logout00={en:Logout 00;zh:登出次数00},  Logout01={en:Logout 01;zh:登出次数01},  Logout02={en:Logout 02;zh:登出次数02},  Logout03={en:Logout 03;zh:登出次数03},  Logout04={en:Logout 04;zh:登出次数04},  Logout05={en:Logout 05;zh:登出次数05},  Logout06={en:Logout 06;zh:登出次数06},  Logout07={en:Logout 07;zh:登出次数07},  Logout08={en:Logout 08;zh:登出次数08},  Logout09={en:Logout 09;zh:登出次数09},  Logout00Time={en:Logout00 Time;zh:登出时长00},  Logout01Time={en:Logout01 Time;zh:登出时长01},  Logout02Time={en:Logout02 Time;zh:登出时长02},  Logout03Time={en:Logout03 Time;zh:登出时长03},  Logout04Time={en:Logout04 Time;zh:登出时长04},  Logout05Time={en:Logout05 Time;zh:登出时长05},  Logout06Time={en:Logout06 Time;zh:登出时长06},  Logout07Time={en:Logout07 Time;zh:登出时长07},  Logout08Time={en:Logout08 Time;zh:登出时长08},  Logout09Time={en:Logout09Time;zh:登出时长09},  RepDate={en:Report Date;zh:报表日期}', null, '', '', '', '', '', 'LoginTime=time_sec,  ReadyTime=time_sec, AcwTime=time_sec,  TalkTime=time_sec,  IdleTime=time_sec,  NotReady00Time=time_sec, NotReady01Time=time_sec,  NotReady02Time=time_sec,  NotReady03Time=time_sec,  NotReady04Time=time_sec,  NotReady05Time=time_sec, NotReady06Time=time_sec,  NotReady07Time=time_sec,  NotReady08Time=time_sec, NotReady09Time=time_sec, Logout00Time=time_sec,  Logout01Time=time_sec, Logout02Time=time_sec, Logout03Time=time_sec, Logout04Time=time_sec, Logout05Time=time_sec, Logout06Time=time_sec, Logout07Time=time_sec, Logout08Time=time_sec, Logout09Time=time_sec', '', '', '', 'YearSch=RepDate,  PrjId=Project ID,  Agent=Agent', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.call.truck.stat', '{zh:中继呼叫统计,en:Call Truck Statistics}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_stat_call_trunk  @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'projectid,period=group_level,begdate=DateBegin,enddate=DateEnd,begtime=TimeBegin,endtime=TimeEnd', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.call.wait.dist', '{zh:放弃电话等待时长分析,en:Wating Time of Missed Call Analyses}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_dist_call_waiting @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'projectid,begdate=DateBegin,enddate=DateEnd,syn,begtime=TimeBegin,endtime=TimeEnd,schkeyname=sch_key', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.callvol.pressurel', '{zh:话务压力分析,en:Telephone Traffic Pressure Analysis}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.kpi.sp_callvol_pressure @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'projectid,begdate=DateBegin,enddate=DateEnd,period=GroupLevel,begtime=TimeBegin,endtime=TimeEnd,schkeyname=schvalue', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.device.stat.dist', '{zh:坐席分机状态分布,en:Agent Extension Status Distribute}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_dist_device_status @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,Skill,SkillGroup,begtime=TimeBegin,endtime=TimeEnd,groupid,agent,  period=GroupLevel', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.ext.call.stat', '{zh:分机呼叫统计,en:Extension Call Statistics}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_stat_ext_call  @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'projectid,begdate=DateBegin,enddate=DateEnd,extension,period=GroupLevel,begtime=TimeBegin,endtime=TimeEnd,skillgroup,skill,groupid', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.ext.rt.sample', '{zh:分机状态实时采样统计,en:Extension Status Real Time Sample}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_stat_ext_sample @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,Skill,begtime=TimeBegin,endtime=TimeEnd,SkillGroup,groupid,extension', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.ext.status.chg', '{zh:分机状态变化记录,en:Extension State Change Record}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_ext_status_change @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,agent,extension,begtime=TimeBegin,endtime=TimeEnd,Skill,SkillGroup,groupid=GroupId', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.ext.status.stat', '{zh:分机状态统计,en:Extension State Statistics}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_stat_ext_status @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,agent,extension,begtime=TimeBegin,endtime=TimeEnd,Skill,SkillGroup,groupid=GroupId', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.ext.timing.sample', '{zh:分机状态时序采样统计,en:Extension Status Time Series Sample}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_stat_ext_timing_sample @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,Skill,SkillGroup,begtime=TimeBegin,endtime=TimeEnd,groupid,extension', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.30', '{en:Call Statistic Report (30 Min),zh:呼叫统计报表(30分钟)}', 100, '0', 30301000, 22, 1, 15, 15, -1, 'vxi_rep..stat_call', 'recdt', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', 'stat.call.30.jsp', '', '', '', '', '', '', '', '', '', null, null, '', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', '', null, 'recdt = {en:Record ID;zh:记录号},  timespan = {en:Time Interval;zh:时间间隔},  totalnum = {en:Call Volume;zh:呼叫量},  totaltm = {en:Calling Time;zh:呼叫时长},  incnum = {en:Inbound Call Volume;zh:呼入量},  inctm = {en:Talk Time;zh:通话时长},  otgnum = {en:Outbound Call Volume;zh:外呼量},  otgtm = {en:Outbound Taking Time;zh:外呼通话时长},  insnum = {en:Inter Call;zh:内部呼叫量},  instm = {en:Internal Talk Time;zh:内部呼叫时长},  ansnum = {en:Answered Call Volume;zh:应答数},  anslessnum = {en:Answered Less Than 15s;zh:15秒内应答量},  ansmorenum = {en:Answered More Than 15s;zh:15秒外应答量},  connum = {en:Call Volume Sum;zh:呼叫合并},  trsnum = {en:Call Transfer;zh:呼叫转移量},  abannum = {en:Abandond Call;zh:呼叫放弃量},  abanlessnum = {Abandond within 20s;zh:20秒内放弃呼叫量},  abanmorenum = {Abandond After 20s;zh:20秒后放弃呼叫量},  abantm = {Abandond Time;zh:放弃时长},  maxwaittm = {en:Max Wait Time;zh:最大等待时长},  worktm = {en:Work Time;zh:工作时长},  abanqueuenum = {en:Abandond Queue Num;zh:队列放弃呼叫量},  abanagentnum = {en:Abandond Agent Num;zh:座席放弃呼叫量},  anstm ={en:Answer Time;zh:应答时长}  ', null, null, null, null, null, '', 'TotalTm=timestamp, IncTm=timestamp, OtgTm=timestamp, InsTm=timestamp, AbanTm=timestamp, MaxWaitTm=timestamp, AnsTm=timestamp, WorkTm=timestamp', null, '', null, 'RecDT=Record ID', 'select m.recdt, m.TimeSpan, m.TotalNum, m.TotalTm, m.IncNum, m.IncTm, m.OtgNum, m.OtgTm, m.InsNum, m.InsTm, m.AnsNum, m.AnsLessNum, m.AnsMoreNum, m.ConNum, m.TrsNum, m.AbanNum, m.AbanLessNum, m.AbanMoreNum, m.AbanTm, m.MaxWaitTm, m.AnsTm, m.WorkTm, m.AbanQueueNum, m.AbanAgentNum from vxi_ucd..stat_call m', 'select m.recdt, m.TimeSpan, m.TotalNum, m.TotalTm, m.IncNum, m.IncTm, m.OtgNum, m.OtgTm, m.InsNum, m.InsTm, m.AnsNum, m.AnsLessNum, m.AnsMoreNum, m.ConNum, m.TrsNum, m.AbanNum, m.AbanLessNum, m.AbanMoreNum, m.AbanTm, m.MaxWaitTm, m.AnsTm, m.WorkTm, m.AbanQueueNum, m.AbanAgentNum from vxi_ucd..stat_call m where m.recdt = !recdt', 'select m.recdt, m.TimeSpan, m.TotalNum, m.TotalTm, m.IncNum, m.IncTm, m.OtgNum, m.OtgTm, m.InsNum, m.InsTm, m.AnsNum, m.AnsLessNum, m.AnsMoreNum, m.ConNum, m.TrsNum, m.AbanNum, m.AbanLessNum, m.AbanMoreNum, m.AbanTm, m.MaxWaitTm, m.AnsTm, m.WorkTm, m.AbanQueueNum, m.AbanAgentNum from vxi_ucd..stat_call m where m.recdt = !recdt', '', '', '', '', null, '', null, null, null, '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.kpi.agent.rate', '{zh:员工四率管理,en:Agent Manage(4 Rate)}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.kpi.sp_agent_rate  @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,Skill,begtime=TimeBegin,endtime=TimeEnd,SkillGroup,groupid,period=GroupLevel', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.kpi.all.stat', '{zh:KPI综合统计,en:KPI General Statistics}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.kpi.sp_all_stat @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'projectid,begdate=DateBegin,enddate=DateEnd,period=GroupLevel,begtime=TimeBegin,endtime=TimeEnd,schkeyname=schkey', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('rep.rt.agent.stat', '{zh:坐席实时状态变化,en:Agent Real Time Status Changes}', 100, null, 70000000, 65, 1, 15, 15, -1, '', '', null, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.rep.search.jsp', null, '', null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep.stat.sp_rt_agent_status @preload=!preload', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'BegDate=date, EndDate=date, BegTime=time, EndTime=time, recDate=date', null, null, null, 'ProjectId,begdate=DateBegin,enddate=DateEnd,Skill,begtime=TimeBegin,endtime=TimeEnd,SkillGroup,groupid,agent', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.agent.report.day', '{zh:座席呼叫统计报表(日报),en:Agent Call Statistic Report (Daily)}', 100, '0', 30302000, 23, 1, 15, 15, -1, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_call_agent_report', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'prjid={en:Project ID;zh:项目},  RecDT={zh:日期;en:Date},  Agent={zh:座席;en:Agent},  TotalCall={zh:呼叫总数;en:Total Call},  SkillCall={zh:技能组呼入数;en:Skill Call},  SkillAns={zh:技能组应答数;en:Skill Ans},  AnsLess={zh:及时应答(15秒);en:Ans Less},  AnsMore={zh:超时应答(15秒);en:Ans More},  CallAban={zh:放弃总数;en:Call Aban},  AbanRate={zh:放弃率;en:Aban Rate},  AbanLess={zh:放弃(15秒)时限内;en:Aban Less},  AbanMore={zh:放弃(15秒)时限外;en:Aban More},  TalkTime={zh:通话时长;en:Talk Time},  InTalk={zh:通话呼入;en:In Talk},  OutTalk={zh:通话呼出;en:Out Talk},  InnerTalk={zh:内部通话;en:Inner Talk},  AvgTalkTime={zh:通话平均时长;en:Avg Talk Time},  AvgAcdTime={zh:技能组平均时长;en:Avg Acd Time},  AvgAnsTime={zh:技能组平均应答速度;en:Avg Ans Time},  AvgHoldTime={zh:平均保持时长;en:Avg Hold Time},  AvgAcwTime={zh:平均话后工作时长;en:Avg Acw Time},  AvgHandleTime={zh:平均处理时长;en:Avg Handle Time},  CallTrans={zh:呼叫转移总数;en:Call Trans},  CallTransRate={zh:转接率;en:Call Trans Rate},  CallConf={zh:会议呼叫数;en:Call Conf},  CallTrunk={zh:中继呼叫总数;en:Call Trunk},  TrunkIn={zh:中继呼入数量;en:Trunk In},  TrunkInAns={zh:中继呼入应答;en:Trunk In Ans},  TrunkOut={zh:中继呼出数量;en:Trunk Out},  TrunkOutAns={zh:中继呼出应答;en:Trunk Out Ans},  TalkLess10={zh:外拨通话10秒内;en:Talk Less10},  TalkLess20={zh:外拨通话20秒内;en:Talk Less20},  TalkMore20={zh:外拨通话大于20秒;en:Talk More20},  LoginTime={zh:总工作时长;en:Login Time},  AvailTime={zh:总可用时长;en:Avail Time},  AvailRate={zh:可用率;en:Avail Rate},  Occupancy={zh:占用率;en:Occupancy},  RepDate={zh:日期en:Date}', null, '', '', '', '', '', 'TalkTime=time_sec,  AvgTalkTime=time_sec,  AvgAcdTime=time_sec,  AvgAnsTime=time_sec,  AvgHoldTime=time_sec,  AvgAcwTime=time_sec,  AvgHandleTime=time_sec,  LoginTime=time_sec,  AvailTime=time_sec,  AbanRate=0%,  AvailRate=0%,   Occupancy=0%,   CallTransRate=0%', '', '', '', 'DateSch=RepDate,  PrjId=Project ID,  Agent=Agent', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.agent.report.month', '{zh:座席呼叫统计报表(月报),en:Agent Call Statistic Report (Monthly)}', 100, '0', 30302000, 23, 1, 15, 15, -1, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_call_agent_report', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'prjid={en:Project ID;zh:项目},  RecDT={zh:日期;en:Date},  Agent={zh:座席;en:Agent},  TotalCall={zh:呼叫总数;en:Total Call},  SkillCall={zh:技能组呼入数;en:Skill Call},  SkillAns={zh:技能组应答数;en:Skill Ans},  AnsLess={zh:及时应答(15秒);en:Ans Less},  AnsMore={zh:超时应答(15秒);en:Ans More},  CallAban={zh:放弃总数;en:Call Aban},  AbanRate={zh:放弃率;en:Aban Rate},  AbanLess={zh:放弃(15秒)时限内;en:Aban Less},  AbanMore={zh:放弃(15秒)时限外;en:Aban More},  TalkTime={zh:通话时长;en:Talk Time},  InTalk={zh:通话呼入;en:In Talk},  OutTalk={zh:通话呼出;en:Out Talk},  InnerTalk={zh:内部通话;en:Inner Talk},  AvgTalkTime={zh:通话平均时长;en:Avg Talk Time},  AvgAcdTime={zh:技能组平均时长;en:Avg Acd Time},  AvgAnsTime={zh:技能组平均应答速度;en:Avg Ans Time},  AvgHoldTime={zh:平均保持时长;en:Avg Hold Time},  AvgAcwTime={zh:平均话后工作时长;en:Avg Acw Time},  AvgHandleTime={zh:平均处理时长;en:Avg Handle Time},  CallTrans={zh:呼叫转移总数;en:Call Trans},  CallTransRate={zh:转接率;en:Call Trans Rate},  CallConf={zh:会议呼叫数;en:Call Conf},  CallTrunk={zh:中继呼叫总数;en:Call Trunk},  TrunkIn={zh:中继呼入数量;en:Trunk In},  TrunkInAns={zh:中继呼入应答;en:Trunk In Ans},  TrunkOut={zh:中继呼出数量;en:Trunk Out},  TrunkOutAns={zh:中继呼出应答;en:Trunk Out Ans},  TalkLess10={zh:外拨通话10秒内;en:Talk Less10},  TalkLess20={zh:外拨通话20秒内;en:Talk Less20},  TalkMore20={zh:外拨通话大于20秒;en:Talk More20},  LoginTime={zh:总工作时长;en:Login Time},  AvailTime={zh:总可用时长;en:Avail Time},  AvailRate={zh:可用率;en:Avail Rate},  Occupancy={zh:占用率;en:Occupancy},  RepDate={zh:日期en:Date}', null, '', '', '', '', '', 'TalkTime=time_sec,  AvgTalkTime=time_sec,  AvgAcdTime=time_sec,  AvgAnsTime=time_sec,  AvgHoldTime=time_sec,  AvgAcwTime=time_sec,  AvgHandleTime=time_sec,  LoginTime=time_sec,  AvailTime=time_sec,  AbanRate=0%,  AvailRate=0%,   Occupancy=0%,   CallTransRate=0%', '', '', '', 'MonthSch=RepDate,  PrjId=Project ID,  Agent=Agent', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.agent.report.range', '{zh:座席呼叫统计报表,en:Agent Call Statistic Report (Range)}', 100, '0', 30302000, 23, 1, 15, 15, -1, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_call_agent_report', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'prjid={en:Project ID;zh:项目},  RecDT={zh:日期;en:Date},  Agent={zh:座席;en:Agent},  TotalCall={zh:呼叫总数;en:Total Call},  SkillCall={zh:技能组呼入数;en:Skill Call},  SkillAns={zh:技能组应答数;en:Skill Ans},  AnsLess={zh:及时应答(15秒);en:Ans Less},  AnsMore={zh:超时应答(15秒);en:Ans More},  CallAban={zh:放弃总数;en:Call Aban},  AbanRate={zh:放弃率;en:Aban Rate},  AbanLess={zh:放弃(15秒)时限内;en:Aban Less},  AbanMore={zh:放弃(15秒)时限外;en:Aban More},  TalkTime={zh:通话时长;en:Talk Time},  InTalk={zh:通话呼入;en:In Talk},  OutTalk={zh:通话呼出;en:Out Talk},  InnerTalk={zh:内部通话;en:Inner Talk},  AvgTalkTime={zh:通话平均时长;en:Avg Talk Time},  AvgAcdTime={zh:技能组平均时长;en:Avg Acd Time},  AvgAnsTime={zh:技能组平均应答速度;en:Avg Ans Time},  AvgHoldTime={zh:平均保持时长;en:Avg Hold Time},  AvgAcwTime={zh:平均话后工作时长;en:Avg Acw Time},  AvgHandleTime={zh:平均处理时长;en:Avg Handle Time},  CallTrans={zh:呼叫转移总数;en:Call Trans},  CallTransRate={zh:转接率;en:Call Trans Rate},  CallConf={zh:会议呼叫数;en:Call Conf},  CallTrunk={zh:中继呼叫总数;en:Call Trunk},  TrunkIn={zh:中继呼入数量;en:Trunk In},  TrunkInAns={zh:中继呼入应答;en:Trunk In Ans},  TrunkOut={zh:中继呼出数量;en:Trunk Out},  TrunkOutAns={zh:中继呼出应答;en:Trunk Out Ans},  TalkLess10={zh:外拨通话10秒内;en:Talk Less10},  TalkLess20={zh:外拨通话20秒内;en:Talk Less20},  TalkMore20={zh:外拨通话大于20秒;en:Talk More20},  LoginTime={zh:总工作时长;en:Login Time},  AvailTime={zh:总可用时长;en:Avail Time},  AvailRate={zh:可用率;en:Avail Rate},  Occupancy={zh:占用率;en:Occupancy},  RepDate={zh:日期en:Date}', null, '', '', '', '', '', 'TalkTime=time_sec,  AvgTalkTime=time_sec,  AvgAcdTime=time_sec,  AvgAnsTime=time_sec,  AvgHoldTime=time_sec,  AvgAcwTime=time_sec,  AvgHandleTime=time_sec,  LoginTime=time_sec,  AvailTime=time_sec,  AbanRate=0%,  AvailRate=0%,   Occupancy=0%,   CallTransRate=0%', '', '', '', 'TimeRange=Time,  PrjId=Project ID,Agent=Agent', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.agent.report.year', '{zh:座席呼叫统计报表(年报),en:Agent Call Statistic Report (Annually)}', 100, '0', 30302000, 23, 1, 15, 15, -1, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_call_agent_report', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'prjid={en:Project ID;zh:项目},  RecDT={zh:日期;en:Date},  Agent={zh:座席;en:Agent},  TotalCall={zh:呼叫总数;en:Total Call},  SkillCall={zh:技能组呼入数;en:Skill Call},  SkillAns={zh:技能组应答数;en:Skill Ans},  AnsLess={zh:及时应答(15秒);en:Ans Less},  AnsMore={zh:超时应答(15秒);en:Ans More},  CallAban={zh:放弃总数;en:Call Aban},  AbanRate={zh:放弃率;en:Aban Rate},  AbanLess={zh:放弃(15秒)时限内;en:Aban Less},  AbanMore={zh:放弃(15秒)时限外;en:Aban More},  TalkTime={zh:通话时长;en:Talk Time},  InTalk={zh:通话呼入;en:In Talk},  OutTalk={zh:通话呼出;en:Out Talk},  InnerTalk={zh:内部通话;en:Inner Talk},  AvgTalkTime={zh:通话平均时长;en:Avg Talk Time},  AvgAcdTime={zh:技能组平均时长;en:Avg Acd Time},  AvgAnsTime={zh:技能组平均应答速度;en:Avg Ans Time},  AvgHoldTime={zh:平均保持时长;en:Avg Hold Time},  AvgAcwTime={zh:平均话后工作时长;en:Avg Acw Time},  AvgHandleTime={zh:平均处理时长;en:Avg Handle Time},  CallTrans={zh:呼叫转移总数;en:Call Trans},  CallTransRate={zh:转接率;en:Call Trans Rate},  CallConf={zh:会议呼叫数;en:Call Conf},  CallTrunk={zh:中继呼叫总数;en:Call Trunk},  TrunkIn={zh:中继呼入数量;en:Trunk In},  TrunkInAns={zh:中继呼入应答;en:Trunk In Ans},  TrunkOut={zh:中继呼出数量;en:Trunk Out},  TrunkOutAns={zh:中继呼出应答;en:Trunk Out Ans},  TalkLess10={zh:外拨通话10秒内;en:Talk Less10},  TalkLess20={zh:外拨通话20秒内;en:Talk Less20},  TalkMore20={zh:外拨通话大于20秒;en:Talk More20},  LoginTime={zh:总工作时长;en:Login Time},  AvailTime={zh:总可用时长;en:Avail Time},  AvailRate={zh:可用率;en:Avail Rate},  Occupancy={zh:占用率;en:Occupancy},  RepDate={zh:日期en:Date}', null, '', '', '', '', '', 'TalkTime=time_sec,  AvgTalkTime=time_sec,  AvgAcdTime=time_sec,  AvgAnsTime=time_sec,  AvgHoldTime=time_sec,  AvgAcwTime=time_sec,  AvgHandleTime=time_sec,  LoginTime=time_sec,  AvailTime=time_sec,  AbanRate=0%,  AvailRate=0%,   Occupancy=0%,   CallTransRate=0%', '', '', '', 'YearSch=RepDate,  PrjId=Project ID,  Agent=Agent', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report', '{en:Call Statistic Report,zh:呼叫统计报表}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', '', 0, 0, 0, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', '', null, null, null, null, null, null, null, '', 'TotalTm=time_sec, TotalAvgTm=time_sec, IncTm=time_sec, IncAvgTm=time_sec,   OtgTm=time_sec, OtgAvgTm=time_sec, InsTm=time_sec, InsAvgTm=time_sec, AbanTm=time_sec,   AbanAvgTm=time_sec, MaxWaitTm=time_sec, AnsTm=time_sec, AnsAvgTm=time_sec,   WorkTm=time_sec,  LoginTime=time_sec', null, '', null, 'TimeRange=time,RecDT=Report Date', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report.agent_g_all', '{en:Agent Status Report,zh:坐席状态报表}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', ' group_level=all, sch_value=Agent ID', null, null, null, null, null, null, null, '', null, null, '', null, 'TimeRange=time, RecDT=Report Date', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report.agent_g_day', '{en:Agent Status Report (Daily),zh:坐席状态报表(日报)}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=agent_g, group_level=day', null, null, null, null, null, null, null, '', 'TotalTm=time_sec, TotalAvgTm=time_sec, IncTm=time_sec, IncAvgTm=time_sec,   OtgTm=time_sec, OtgAvgTm=time_sec, InsTm=time_sec, InsAvgTm=time_sec, AbanTm=time_sec,   AbanAvgTm=time_sec, MaxWaitTm=time_sec, AnsTm=time_sec, AnsAvgTm=time_sec,   WorkTm=time_sec, LoginTime=time_sec, TotalTmN=time_sec, IncTmN=time_sec, OtgTmN=time_sec,   FreeTime=time_sec, NotReadyTime=time_sec, RingTm=time_sec', null, '', null, 'TimeRange=time,RecDT=Report Date,sch_value=Agent ID', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report.agent_g_month', '{en:Agent Status Report (Monthly),zh:坐席状态?ū?月报)}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=agent_g, group_level=month', null, null, null, null, null, null, null, '', 'TotalTm=time_sec, TotalAvgTm=time_sec, IncTm=time_sec, IncAvgTm=time_sec,   OtgTm=time_sec, OtgAvgTm=time_sec, InsTm=time_sec, InsAvgTm=time_sec, AbanTm=time_sec,   AbanAvgTm=time_sec, MaxWaitTm=time_sec, AnsTm=time_sec, AnsAvgTm=time_sec,   WorkTm=time_sec, LoginTime=time_sec, TotalTmN=time_sec, IncTmN=time_sec, OtgTmN=time_sec,   FreeTime=time_sec, NotReadyTime=time_sec, RingTm=time_sec', null, '', null, 'TimeRange=time,RecDT=Report Date,sch_value=Agent ID', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report.agent_g_rec', '{en:Agent Status Report (Hourly),zh:坐席状态报表(时报)}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=agent_g, group_level=record', null, 'RecDT=日期,agent=座席代码, GroupId=组,TimeSpan=时间<br>间隔,  TotalNum=总呼<br>叫数, TotalTm=总通话<br>时间, TotalAvgTm=平  均呼<br>叫时长, IncNum=总呼入数, IncTm=呼入通<br>话时间, IncAvgTm=平均呼<br>入时长, OtgNum=呼出<br>  数, OtgTm=呼出通<br>话时间, OtgAvgTm=平均呼<br>出时长, InsNum=内部<br>呼叫数, InsTm=内部通<br>话时间, InsAvgTm=  平均内<br>部时长, AnsNum=呼入<br>数, AnsLessNum=规定值内<br>应答总数, AnsMoreNum=规定值后<br>  应答总数, AnsTm=应答<br>时长, AnsAvgTm=平均应<br>答时长, ConNum=呼叫合<br>并数量, TrsNum=呼叫  转<br>移数量, AbanNum=中断呼<br>叫数量, AbanLessNum=规定值内<br>中断数量, AbanMoreNum=规定值  外<br>中断数量, AbanTm=中断时长, AbanAvgTm=平均中<br>断时长, MaxWaitTm=最大等<br>待时长,   WorkTm=工作时长, AbanQueueNum=对列中<br>断数量, AbanAgentNum=座席中<br>断数量, LoginTime=登录时间, TotalTmL=通话时间%, TotalNumL=呼叫/小时, TotalTmN=平均通<br>话时间S, IncTmL=呼入时间%, AnsNumL=呼入/小时, IncTmN=呼入平均<br>通话时间, OtgTmL=呼出时间%, OtgNumL=呼出/小时, OtgTmN=呼出平均<br>通话时间, InsTmL=内部时间%, InsNumL=内部/小时, InsTmN=内部平均<br>通话时间, FreeTime=等待<br>时间Hr, FreeTimeL=等待<br>时间%, NotReadyTime=未准备<br>好时间Hr, NotReadyTimeL=未准备<br>好时间%, RingTm=振铃<br>时间Hr, RingTmL=振铃<br>时间%, Efficiency=直接工<br>作效率', null, null, null, null, null, '', 'TotalTm=time_sec, TotalAvgTm=time_sec, IncTm=time_sec, IncAvgTm=time_sec,   OtgTm=time_sec, OtgAvgTm=time_sec, InsTm=time_sec, InsAvgTm=time_sec, AbanTm=time_sec,   AbanAvgTm=time_sec, MaxWaitTm=time_sec, AnsTm=time_sec, AnsAvgTm=time_sec,   WorkTm=time_sec, LoginTime=time_sec, TotalTmN=time_sec, IncTmN=time_sec, OtgTmN=time_sec,   FreeTime=time_sec, NotReadyTime=time_sec, RingTm=time_sec', null, '', null, 'TimeRange=time,RecDT=Report Date,sch_value=Agent ID', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report.agent_g_week', '{en:Agent Status Report (Weekly),zh:坐席状态报表(周报)}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=agent_g, group_level=week', null, 'RecDT=日期,agent=座席代码, GroupId=组,TimeSpan=时间<br>间隔,  TotalNum=总呼<br>叫数, TotalTm=总通话<br>时间, TotalAvgTm=平均呼<br>叫时长, IncNum=总呼入数, IncTm=呼入通<br>话时间, IncAvgTm=平均呼<br>入时长,   OtgNum=呼出<br>数, OtgTm=呼出通<br>话时间, OtgAvgTm=平均呼<br>出时长, InsNum=内部<br>呼叫数,   InsTm=内部通<br>话时间, InsAvgTm=平均内<br>部时长,   AnsNum=呼入<br>数, AnsLessNum=规定值内<br>应答总数, AnsMoreNum=规定值后<br>应答总数,   AnsTm=应答<br>时长, AnsAvgTm=平均应<br>答时长, ConNum=呼叫合<br>并数量,   TrsNum=呼叫转<br>移数量, AbanNum=中断呼<br>叫数量, AbanLessNum=规定值内<br>中断数量,   AbanMoreNum=规定值外<br>中断数量, AbanTm=中断时长, AbanAvgTm=平均中<br>断时长,   MaxWaitTm=最大等<br>待时长, WorkTm=工作时长, AbanQueueNum=对列中<br>断数量,   AbanAgentNum=座席中<br>断数量, LoginTime=登录时间, TotalTmL=通话时间%, TotalNumL=呼叫/小时,   TotalTmN=平均通<br>话时间S, IncTmL=呼入时间%, AnsNumL=呼入/小时, IncTmN=呼入平均<br>通话时间,   OtgTmL=呼出时间%, OtgNumL=呼出/小时, OtgTmN=呼出平均<br>通话时间, InsTmL=内部时间%, InsNumL=内部/小时, InsTmN=内部平均<br>通话时间, FreeTime=等待<br>时间Hr, FreeTimeL=等待<br>时间%,   NotReadyTime=未准备<br>好时间Hr, NotReadyTimeL=未准备<br>好时间%, RingTm=振铃<br>时间Hr,   RingTmL=振铃<br>时间%, Efficiency=直接工<br>作效率', null, null, null, null, null, '', 'TotalTm=time_sec, TotalAvgTm=time_sec, IncTm=time_sec, IncAvgTm=time_sec,   OtgTm=time_sec, OtgAvgTm=time_sec, InsTm=time_sec, InsAvgTm=time_sec, AbanTm=time_sec,   AbanAvgTm=time_sec, MaxWaitTm=time_sec, AnsTm=time_sec, AnsAvgTm=time_sec,   WorkTm=time_sec, LoginTime=time_sec, TotalTmN=time_sec, IncTmN=time_sec, OtgTmN=time_sec,   FreeTime=time_sec, NotReadyTime=time_sec, RingTm=time_sec', null, '', null, 'TimeRange=time,RecDT=Report Date,sch_value=Agent ID', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report.agent_g_year', '{en:Agent Status Report (Annually),zh:坐席状态报表(年报)}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=agent_g, group_level=year', null, 'RecDT=日期,agent=座席代码, GroupId=组,TimeSpan=时间<br>间隔,  TotalNum=总呼<br>叫数, TotalTm=总通话<br>时间, TotalAvgTm=平  均呼<br>叫时长, IncNum=总呼入数, IncTm=呼入通<br>话时间, IncAvgTm=平均呼<br>入时长, OtgNum=呼出<br>  数, OtgTm=呼出通<br>话时间, OtgAvgTm=平均呼<br>出时长, InsNum=内部<br>呼叫数, InsTm=内部通<br>话时间, InsAvgTm=  平均内<br>部时长, AnsNum=呼入<br>数, AnsLessNum=规定值内<br>应答总数, AnsMoreNum=规定值后<br>  应答总数, AnsTm=应答<br>时长, AnsAvgTm=平均应<br>答时长, ConNum=呼叫合<br>并数量, TrsNum=呼叫  转<br>移数量, AbanNum=中断呼<br>叫数量, AbanLessNum=规定值内<br>中断数量, AbanMoreNum=规定值  外<br>中断数量, AbanTm=中断时长, AbanAvgTm=平均中<br>断时长, MaxWaitTm=最大等<br>待时长,   WorkTm=工作时长, AbanQueueNum=对列中<br>断数量, AbanAgentNum=座席中<br>断数量, LoginTime=登录时间, TotalTmL=通话时间%, TotalNumL=呼叫/小时, TotalTmN=平均通<br>话时间S, IncTmL=呼入时间%, AnsNumL=呼入/小时, IncTmN=呼入平均<br>通话时间, OtgTmL=呼出时间%, OtgNumL=呼出/小时, OtgTmN=呼出平均<br>通话时间, InsTmL=内部时间%, InsNumL=内部/小时, InsTmN=内部平均<br>通话时间, FreeTime=等待<br>时间Hr, FreeTimeL=等待<br>时间%, NotReadyTime=未准备<br>好时间Hr, NotReadyTimeL=未准备<br>好时间%, RingTm=振铃<br>时间Hr, RingTmL=振铃<br>时间%, Efficiency=直接工<br>作效率', null, null, null, null, null, '', 'TotalTm=time_sec, TotalAvgTm=time_sec, IncTm=time_sec, IncAvgTm=time_sec,   OtgTm=time_sec, OtgAvgTm=time_sec, InsTm=time_sec, InsAvgTm=time_sec, AbanTm=time_sec,   AbanAvgTm=time_sec, MaxWaitTm=time_sec, AnsTm=time_sec, AnsAvgTm=time_sec,   WorkTm=time_sec, LoginTime=time_sec, TotalTmN=time_sec, IncTmN=time_sec, OtgTmN=time_sec,   FreeTime=time_sec, NotReadyTime=time_sec, RingTm=time_sec', null, '', null, 'TimeRange=time,RecDT=Report Date,sch_value=Agent ID', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report.ext', '{en:Extension Call Statistic Report,zh:分机呼叫统计报表}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=ext', null, 'RecDT=Date&Time, Ext=Extension, TimeSpan=Time <br>Interval,  TotalNum=Call<br>Volume, TotalTm=Call Time, TotalAvgTm=Average 均呼<br>叫时长, IncNum=呼入<br>数量, IncTm=呼入时长, IncAvgTm=平均呼<br>入时长, OtgNum=呼出<br>数量, OtgTm=呼出时长, OtgAvgTm=平均呼<br>出时长, InsNum=内部<br>呼叫, InsTm=内部时长,   InsAvgTm=平均内<br>部时长, AnsNum=应答<br>总数, AnsLessNum=规定值内<br>应答总数, AnsMoreNum=规定值后<br>应答总数, AnsTm=应答<br>时长, AnsAvgTm=平均应<br>答时长, ConNum=呼叫合<br>并数量,   TrsNum=呼叫转<br>移数量, AbanNum=中断呼<br>叫数量, AbanLessNum=规定值内<br>中断数量,   AbanMoreNum=规定值外<br>中断数量, AbanTm=中断时长, AbanAvgTm=平均中<br>断时长,   MaxWaitTm=最大等<br>待时长,   WorkTm=工作时长, AbanQueueNum=对列中<br>断数量, AbanAgentNum=座席中<br>断数量', null, null, null, null, null, '', 'TotalTm=time_sec, TotalAvgTm=time_sec, IncTm=time_sec, IncAvgTm=time_sec,   OtgTm=time_sec, OtgAvgTm=time_sec, InsTm=time_sec, InsAvgTm=time_sec, AbanTm=time_sec,   AbanAvgTm=time_sec, MaxWaitTm=time_sec, AnsTm=time_sec, AnsAvgTm=time_sec,   WorkTm=time_sec,  LoginTime=time_sec', null, '', null, 'TimeRange=time,RecDT=Report Date,sch_value=Extension', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report.skill', '{en:Skill Call Statistic Report,zh:技能组呼叫统计报表}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', 'RecDT', 1, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', 'nil', '', '', null, null, null, null, null, null, null, null, null, '', '', 'sch_key=skill', '', 'RecDT=Date&Time, skill=Skill<br>Code, TimeSpan=Time<br>Interval,  TotalNum=Call<br>Volume, TotalTm=Call Time, TotalAvgTm=平  均呼<br>叫时长, IncNum=呼入<br>数量, IncTm=呼入时长, IncAvgTm=平均呼<br>入时长, OtgNum=呼出<br>  数量, OtgTm=呼出时长, OtgAvgTm=平均呼<br>出时长, InsNum=内部<br>呼叫, InsTm=内部时长, InsAvgTm=  平均内<br>部时长, AnsNum=应答<br>总数, AnsLessNum=规定值内<br>应答总数, AnsMoreNum=规定值后<br>  应答总数, AnsTm=应答<br>时长, AnsAvgTm=平均应<br>答时长, ConNum=呼叫合<br>并数量, TrsNum=呼叫  转<br>移数量, AbanNum=中断呼<br>叫数量, AbanLessNum=规定值内<br>中断数量, AbanMoreNum=规定值  外<br>中断数量, AbanTm=中断时长, AbanAvgTm=平均中<br>断时长, MaxWaitTm=最大等<br>待时长,   WorkTm=工作时长, AbanQueueNum=对列中<br>断数量, AbanAgentNum=座席中<br>断数量', null, null, null, null, null, '', 'TotalTm=time_sec, TotalAvgTm=time_sec, IncTm=time_sec, IncAvgTm=time_sec,   OtgTm=time_sec, OtgAvgTm=time_sec, InsTm=time_sec, InsAvgTm=time_sec, AbanTm=time_sec,   AbanAvgTm=time_sec, MaxWaitTm=time_sec, AnsTm=time_sec, AnsAvgTm=time_sec,   WorkTm=time_sec,  LoginTime=time_sec', null, '', null, 'TimeRange=time,RecDT=Report Date,sch_value=ACD ID', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report.total_day', '{en:Skill Call Statistic Report (Daily),zh:技能组呼叫统计报表(日报)}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=agent_t, group_level=day', null, 'RecDT=日期时间,agent=座席代码, TimeSpan=时间<br>间隔,  TotalNum=呼叫<br>总数, TotalTm=呼叫时长, TotalAvgTm=平  均呼<br>叫时长, IncNum=来电<br>总数, IncTm=呼入时长, IncAvgTm=平均呼<br>入时长, OtgNum=呼出<br>  数量, OtgTm=呼出时长, OtgAvgTm=平均呼<br>出时长, InsNum=内部<br>呼叫, InsTm=内部时长, InsAvgTm=  平均内<br>部时长, AnsNum=总应<br>答数, AnsNumI=接听<br>成功率, AnsLessNum=呼叫应答数<br>15秒前, AnsLessNumI=呼叫应答数<br>15秒前%, AnsMoreNum=呼叫应答数<br>15秒后, AnsTm=应答<br>速度, AnsAvgTm=平均应<br>答时长, ConNum=呼叫合<br>并数量, TrsNum=呼叫  转<br>移数量, AbanNum=总放<br>弃数, AbanNumI=总放<br>弃率, AbanLessNum=规定值内<br>中断数量, AbanMoreNum=15秒后<br>放弃数, AbanTm=放弃<br>时间, AbanAvgTm=平均中<br>断时长, MaxWaitTm=最大等<br>待时长,   WorkTm=座席<br>通话时长, AbanQueueNum=对列内<br>放弃, AbanQueueNumAN=队列内<br>放弃%, AbanAgentNum=座席<br>放弃, AbanAgentNumAN=座席<br>放弃%, LoginTime=座席登<br>录时长, Efficiency=座席工<br>作效率', null, null, null, null, null, '', 'TotalTm=time_sec, TotalAvgTm=time_sec, IncTm=time_sec, IncAvgTm=time_sec,   OtgTm=time_sec, OtgAvgTm=time_sec, InsTm=time_sec, InsAvgTm=time_sec, AbanTm=time_sec,   AbanAvgTm=time_sec, MaxWaitTm=time_sec, AnsTm=time_sec, AnsAvgTm=time_sec,   WorkTm=time_sec,  LoginTime=time_sec', null, '', null, 'TimeRange=time,RecDT=Report Date,sch_value=ACD ID', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report.total_month', '{en:Skill Call Statistic Report (Monthly),zh:技能组呼叫统计报表(月报)}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'sch.stat.call.rep.agent_t.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=agent_t, group_level=month', null, 'RecDT=日期时间,agent=座席代码, TimeSpan=时间<br>间隔,  TotalNum=呼叫<br>总数, TotalTm=呼叫时长, TotalAvgTm=平  均呼<br>叫时长, IncNum=来电<br>总数, IncTm=呼入时长, IncAvgTm=平均呼<br>入时长, OtgNum=呼出<br>  数量, OtgTm=呼出时长, OtgAvgTm=平均呼<br>出时长, InsNum=内部<br>呼叫, InsTm=内部时长, InsAvgTm=  平均内<br>部时长, AnsNum=总应<br>答数, AnsNumI=接听<br>成功率, AnsLessNum=呼叫应答数<br>15秒前, AnsLessNumI=呼叫应答数<br>15秒前%, AnsMoreNum=呼叫应答数<br>15秒后, AnsTm=应答<br>速度, AnsAvgTm=平均应<br>答时长, ConNum=呼叫合<br>并数量, TrsNum=呼叫  转<br>移数量, AbanNum=总放<br>弃数, AbanNumI=总放<br>弃率, AbanLessNum=规定值内<br>中断数量, AbanMoreNum=15秒后<br>放弃数, AbanTm=放弃<br>时间, AbanAvgTm=平均中<br>断时长, MaxWaitTm=最大等<br>待时长,   WorkTm=工作时长, AbanQueueNum=对列内<br>放弃, AbanQueueNumAN=队列内<br>放弃%, AbanAgentNum=座席<br>放弃, AbanAgentNumAN=座席<br>放弃%, LoginTime=座席总<br>上线时间, Efficiency=座席工<br>作效率', null, null, null, null, null, '', 'TotalTm=time_sec, TotalAvgTm=time_sec, IncTm=time_sec, IncAvgTm=time_sec,   OtgTm=time_sec, OtgAvgTm=time_sec, InsTm=time_sec, InsAvgTm=time_sec, AbanTm=time_sec,   AbanAvgTm=time_sec, MaxWaitTm=time_sec, AnsTm=time_sec, AnsAvgTm=time_sec,   WorkTm=time_sec,  LoginTime=time_sec', null, '', null, 'TimeRange=time,RecDT=Report Date,sch_value=ACD ID', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report.total_record', '{en:Skill Call Statistic Report (Hourly),zh:技能组呼叫统计报表(时报)}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=agent_t, group_level=record', null, 'RecDT=日期时间,agent=座席代码, TimeSpan=时间<br>间隔,  TotalNum=呼叫<br>总数, TotalTm=呼叫时长, TotalAvgTm=平  均呼<br>叫时长, IncNum=来电<br>总数, IncTm=呼入时长, IncAvgTm=平均呼<br>入时长, OtgNum=呼出<br>  数量, OtgTm=呼出时长, OtgAvgTm=平均呼<br>出时长, InsNum=内部<br>呼叫, InsTm=内部时长, InsAvgTm=  平均内<br>部时长, AnsNum=总应<br>答数, AnsNumI=接听<br>成功率, AnsLessNum=呼叫应答数<br>15秒前, AnsLessNumI=呼叫应答数<br>15秒前%, AnsMoreNum=呼叫应答数<br>15秒后, AnsTm=应答<br>速度, AnsAvgTm=平均应<br>答时长, ConNum=呼叫合<br>并数量, TrsNum=呼叫  转<br>移数量, AbanNum=总放<br>弃数, AbanNumI=总放<br>弃率, AbanLessNum=规定值内<br>中断数量, AbanMoreNum=15秒后<br>放弃数, AbanTm=放弃<br>时间, AbanAvgTm=平均中<br>断时长, MaxWaitTm=最大等<br>待时长,   WorkTm=工作时长, AbanQueueNum=对列内<br>放弃, AbanQueueNumAN=队列内<br>放弃%, AbanAgentNum=座席<br>放弃, AbanAgentNumAN=座席<br>放弃%, LoginTime=座席总<br>上线时间, Efficiency=座席工<br>作效率', null, null, null, null, null, '', 'TotalTm=time_sec, TotalAvgTm=time_sec, IncTm=time_sec, IncAvgTm=time_sec,   OtgTm=time_sec, OtgAvgTm=time_sec, InsTm=time_sec, InsAvgTm=time_sec, AbanTm=time_sec,   AbanAvgTm=time_sec, MaxWaitTm=time_sec, AnsTm=time_sec, AnsAvgTm=time_sec,   WorkTm=time_sec,  LoginTime=time_sec', null, '', null, 'TimeRange=time,RecDT=Report Date,sch_value=ACD ID', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report.total_week', '{en:Skill Call Statistic Report (Weekly),zh:技能组呼叫统计报表(周报)}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=agent_t, group_level=week', null, 'RecDT=日期时间,agent=座席代码, TimeSpan=时间<br>间隔,  TotalNum=呼叫<br>总数, TotalTm=呼叫时长, TotalAvgTm=平  均呼<br>叫时长, IncNum=来电<br>总数, IncTm=呼入时长, IncAvgTm=平均呼<br>入时长, OtgNum=呼出<br>  数量, OtgTm=呼出时长, OtgAvgTm=平均呼<br>出时长, InsNum=内部<br>呼叫, InsTm=内部时长, InsAvgTm=  平均内<br>部时长, AnsNum=总应<br>答数, AnsNumI=接听<br>成功率, AnsLessNum=呼叫应答数<br>15秒前, AnsLessNumI=呼叫应答数<br>15秒前%, AnsMoreNum=呼叫应答数<br>15秒后, AnsTm=应答<br>速度, AnsAvgTm=平均应<br>答时长, ConNum=呼叫合<br>并数量, TrsNum=呼叫  转<br>移数量, AbanNum=总放<br>弃数, AbanNumI=总放<br>弃率, AbanLessNum=规定值内<br>中断数量, AbanMoreNum=15秒后<br>放弃数, AbanTm=放弃<br>时间, AbanAvgTm=平均中<br>断时长, MaxWaitTm=最大等<br>待时长,   WorkTm=工作时长, AbanQueueNum=对列内<br>放弃, AbanQueueNumAN=队列内<br>放弃%, AbanAgentNum=座席<br>放弃, AbanAgentNumAN=座席<br>放弃%, LoginTime=座席总<br>上线时间, Efficiency=座席工<br>作效率', null, null, null, null, null, '', 'TotalTm=time_sec, TotalAvgTm=time_sec, IncTm=time_sec, IncAvgTm=time_sec,   OtgTm=time_sec, OtgAvgTm=time_sec, InsTm=time_sec, InsAvgTm=time_sec, AbanTm=time_sec,   AbanAvgTm=time_sec, MaxWaitTm=time_sec, AnsTm=time_sec, AnsAvgTm=time_sec,   WorkTm=time_sec,  LoginTime=time_sec', null, '', null, 'TimeRange=time,RecDT=Report Date,sch_value=ACD ID', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report.total_year', '{en:Skill Call Statistic Report (Annually),zh:技能组呼叫统计报表(年报)}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=agent_t, group_level=year', null, 'RecDT=日期时间,agent=座席代码, TimeSpan=时间<br>间隔,  TotalNum=呼叫<br>总数, TotalTm=呼叫时长, TotalAvgTm=平  均呼<br>叫时长, IncNum=来电<br>总数, IncTm=呼入时长, IncAvgTm=平均呼<br>入时长, OtgNum=呼出<br>  数量, OtgTm=呼出时长, OtgAvgTm=平均呼<br>出时长, InsNum=内部<br>呼叫, InsTm=内部时长, InsAvgTm=  平均内<br>部时长, AnsNum=总应<br>答数, AnsNumI=接听<br>成功率, AnsLessNum=呼叫应答数<br>15秒前, AnsLessNumI=呼叫应答数<br>15秒前%, AnsMoreNum=呼叫应答数<br>15秒后, AnsTm=应答<br>速度, AnsAvgTm=平均应<br>答时长, ConNum=呼叫合<br>并数量, TrsNum=呼叫  转<br>移数量, AbanNum=总放<br>弃数, AbanNumI=总放<br>弃率, AbanLessNum=规定值内<br>中断数量, AbanMoreNum=15秒后<br>放弃数, AbanTm=放弃<br>时间, AbanAvgTm=平均中<br>断时长, MaxWaitTm=最大等<br>待时长,   WorkTm=工作时长, AbanQueueNum=对列内<br>放弃, AbanQueueNumAN=队列内<br>放弃%, AbanAgentNum=座席<br>放弃, AbanAgentNumAN=座席<br>放弃%, LoginTime=座席总<br>上线时间, Efficiency=座席工<br>作效率', null, null, null, null, null, '', 'TotalTm=time_sec, TotalAvgTm=time_sec, IncTm=time_sec, IncAvgTm=time_sec,   OtgTm=time_sec, OtgAvgTm=time_sec, InsTm=time_sec, InsAvgTm=time_sec, AbanTm=time_sec,   AbanAvgTm=time_sec, MaxWaitTm=time_sec, AnsTm=time_sec, AnsAvgTm=time_sec,   WorkTm=time_sec,  LoginTime=time_sec', null, '', null, 'TimeRange=time,RecDT=Report Date,sch_value=ACD ID', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.call.report.trunk', '{en:Trunk Call Statistic Report,zh:中继呼叫统计报表}', 100, '0', 30400000, 26, 1, 15, 15, -1, '', '', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.search.jsp', null, null, '', '', '', '', '', '', '', '', '', '', '', null, null, 'vxi_rep..sp_sch_stat_call_report', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sch_key=trunk', null, 'RecDT=Date&Time,GrpId=Group ID, TimeSpan=Time<br> Interval,  TotalNum=Total <br> Volume, TotalTm=Total Talking Time, TotalAvgTm=平均呼<br>叫时长, IncNum=呼入<br>数量, IncTm=呼入时长, IncAvgTm=平均呼<br>入时长, OtgNum=呼出<br>数量, OtgTm=呼出时长, OtgAvgTm=平均呼<br>出时长, InsNum=内部<br>呼叫, InsTm=内部时长,   InsAvgTm=平均内<br>部时长,   AnsNum=应答<br>总数, AnsLessNum=规定值内<br>应答总数, AnsMoreNum=规定值后<br>应答总数,   AnsTm=应答<br>时长, AnsAvgTm=平均应<br>答时长, ConNum=呼叫合<br>并数量, TrsNum=呼叫转<br>移数量,   AbanNum=中断呼<br>叫数量, AbanLessNum=规定值内<br>中断数量, AbanMoreNum=规定值外<br>中断数量,   AbanTm=中断时长, AbanAvgTm=平均中<br>断时长, MaxWaitTm=最大等<br>待时长,   WorkTm=工作时长, AbanQueueNum=对列中<br>断数量, AbanAgentNum=座席中<br>断数量', null, null, null, null, null, '', 'TotalTm=time_sec, TotalAvgTm=time_sec, IncTm=time_sec, IncAvgTm=time_sec,   OtgTm=time_sec, OtgAvgTm=time_sec, InsTm=time_sec, InsAvgTm=time_sec, AbanTm=time_sec,   AbanAvgTm=time_sec, MaxWaitTm=time_sec, AnsTm=time_sec, AnsAvgTm=time_sec,   WorkTm=time_sec,  LoginTime=time_sec', null, '', null, 'TimeRange=time,RecDT=Report Date,sch_value=Group ID', '', '', '', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.in.answer.report.day', '{zh:呼入电话应答分布报表(日报),en:Inbound Statistic Answer Report (Daily)}', 100, '', 30304000, 25, 1, 15, 15, 16777215, '', '', 0, 0, 0, '', '', 0, 0, '', '', '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_sd_inbound_answer_report', '', '', '', '', '', '', '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'TimeRange=Time, prjid', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, '', '', '', null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.in.skill.report.day', '{zh:中继呼入呼叫技能组统计日报表,en:Trunk Inbound Statistic Skill Report (Daily)}', 100, '', 30304000, 25, 1, 15, 15, 16777215, '', '', 0, 0, 0, '', '', 0, 0, '', '', '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_sd_skill_in_report', '', '', '', '', '', '', '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'TimeRange=Time,prjid', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, '', '', '', null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.in.trunk.report.day', '{zh:中继呼入呼叫统计报表,en:Trunk Inbound Statistic Report}', 100, null, 30400000, 26, 1, 15, 15, 16777215, '', '', 0, 0, 0, null, null, 0, 0, null, null, null, 1000, 0, 'ext.search.jsp', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'vxi_rep..sp_stat_sd_trunk_in_report', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'TimeRange=Time, groupid', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.skill.in.detail.ans.abn', '{zh:技能组呼入电话报表,en:Skill Inbound Statistic Report}', 100, '', 30400000, 26, 1, 15, 15, 16777215, '', '', 0, 0, 0, '', '', 0, 0, '', '', '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_sd_skill_in_report', '', '', '', '', '', '', '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'TimeRange=Time, skill=skill', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, '', '', '', null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.skill.report.day', '{zh:技能组呼叫统计报表(日报),en:Skill Statistic Report (Daily)}', 100, '0', 30303000, 24, 1, 15, 15, 55295, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_skill_report', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'prjid={en:Project ID;zh:项目},  date_group={en:Group Level;zh:分组类别},  RecDT={en:Date;zh:日期},  Skill={en:Skill;zh:技能组},  CallOffer={en:Call Offer;zh:总呼叫数},  CallAns={en:Call Ans;zh:总应答数},  AnsLess={en:Ans Less;zh:及时应答数},  AnsMore={en:Ans More;zh:超时应答数},  CallAban={en:Call Aban;zh:放弃呼叫数},  AbanRate={en:Aban Rate;zh:放弃率},  AbanSkill={en:Aban Skill;zh:队列放弃数},  AbanAgent={en:Aban Agent;zh:队列放弃数},  AbanLess={en:Aban Less;zh:时限内放弃},  AbanMore={en:Aban More;zh:时限外放弃},  TotalTalkTime={en:Total TalkTime;zh:总通话时间},  AvgTalkTime={en:Avg TalkTime;zh:平均通话时间},  AvgHoldTime={en:Avg HoldTime;zh:平均保持时间},  AvgRingTime={en:Avg RingTime;zh:平均振铃时间},  AvgAcwTime={en:Avg AcwTime;zh:平均话后处理时间},  AvgHandleTime={en:Avg HandleTime;zh:平均处理时间},  SvcLevel={en:Svc Level;zh:服务水平},  CallTrans={en:Call Trans;zh:转接呼叫数},  CallTransRate={en:Call TransRate;zh:转接率},  CallConf={en:Call Conf;zh:会议呼叫数},  LoginTime={en:Login Time;zh:总工作时间},  AvailTime={en:Avail Time;zh:总可用时间},  AvailRate={en:Avail Rate;zh:可用率},  Occupancy={en:Occupancy;zh:占用率},  RepDate={en:Report Date;zh:日期},  TrunkIn={en:Trunk In;zh:中继呼入数},  TrunkInAns={en:Trunk InAns;zh:中继呼入应答数}', null, '', '', '', '', '', 'TotalTalkTime=time_sec,  AvgTalkTime=time_sec,  AvgAcdTime=time_sec,  AvgRingTime=time_sec,  AvgAnsTime=time_sec,  AvgHoldTime=time_sec,  AvgAcwTime=time_sec,  AvgHandleTime=time_sec,  LoginTime=time_sec,  AvailTime=time_sec,  AbanRate=0%,  AvailRate=0%,   Occupancy=0%,   CallTransRate=0%,  SvcLevel=0%', '', '', '', 'DateSch=RepDate,  PrjId=Project ID,  Skill=Skill', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.skill.report.month', '{zh:技能组呼叫统计报表(月报),en:Skill Statistic Report (Monthly)}', 100, '0', 30303000, 24, 1, 15, 15, -1, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_skill_report', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'prjid={en:Project ID;zh:项目},  date_group={en:Group Level;zh:分组类别},  RecDT={en:Date;zh:日期},  Skill={en:Skill;zh:技能组},  CallOffer={en:Call Offer;zh:总呼叫数},  CallAns={en:Call Ans;zh:总应答数},  AnsLess={en:Ans Less;zh:及时应答数},  AnsMore={en:Ans More;zh:超时应答数},  CallAban={en:Call Aban;zh:放弃呼叫数},  AbanRate={en:Aban Rate;zh:放弃率},  AbanSkill={en:Aban Skill;zh:队列放弃数},  AbanAgent={en:Aban Agent;zh:队列放弃数},  AbanLess={en:Aban Less;zh:时限内放弃},  AbanMore={en:Aban More;zh:时限外放弃},  TotalTalkTime={en:Total TalkTime;zh:总通话时间},  AvgTalkTime={en:Avg TalkTime;zh:平均通话时间},  AvgHoldTime={en:Avg HoldTime;zh:平均保持时间},  AvgRingTime={en:Avg RingTime;zh:平均振铃时间},  AvgAcwTime={en:Avg AcwTime;zh:平均话后处理时间},  AvgHandleTime={en:Avg HandleTime;zh:平均处理时间},  SvcLevel={en:Svc Level;zh:服务水平},  CallTrans={en:Call Trans;zh:转接呼叫数},  CallTransRate={en:Call TransRate;zh:转接率},  CallConf={en:Call Conf;zh:会议呼叫数},  LoginTime={en:Login Time;zh:总工作时间},  AvailTime={en:Avail Time;zh:总可用时间},  AvailRate={en:Avail Rate;zh:可用率},  Occupancy={en:Occupancy;zh:占用率},  RepDate={en:Report Date;zh:日期},  TrunkIn={en:Trunk In;zh:中继呼入数},  TrunkInAns={en:Trunk InAns;zh:中继呼入应答数}', null, '', '', '', '', '', 'TotalTalkTime=time_sec,  AvgTalkTime=time_sec,  AvgAcdTime=time_sec,  AvgRingTime=time_sec,  AvgAnsTime=time_sec,  AvgHoldTime=time_sec,  AvgAcwTime=time_sec,  AvgHandleTime=time_sec,  LoginTime=time_sec,  AvailTime=time_sec,  AbanRate=0%,  AvailRate=0%,   Occupancy=0%,   CallTransRate=0%,  SvcLevel=0%', '', '', '', 'MonthSch=RepDate,  PrjId=Project ID,  Skill=Skill', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.skill.report.range', '{zh:技能组呼叫统计报表,en:Skill Statistic Report (Range)}', 100, '0', 30303000, 24, 1, 15, 15, -1, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_skill_report', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'prjid={en:Project ID;zh:项目},  date_group={en:Group Level;zh:分组类别},  RecDT={en:Date;zh:日期},  Skill={en:Skill;zh:技能组},  CallOffer={en:Call Offer;zh:总呼叫数},  CallAns={en:Call Ans;zh:总应答数},  AnsLess={en:Ans Less;zh:及时应答数},  AnsMore={en:Ans More;zh:超时应答数},  CallAban={en:Call Aban;zh:放弃呼叫数},  AbanRate={en:Aban Rate;zh:放弃率},  AbanSkill={en:Aban Skill;zh:队列放弃数},  AbanAgent={en:Aban Agent;zh:队列放弃数},  AbanLess={en:Aban Less;zh:时限内放弃},  AbanMore={en:Aban More;zh:时限外放弃},  TotalTalkTime={en:Total TalkTime;zh:总通话时间},  AvgTalkTime={en:Avg TalkTime;zh:平均通话时间},  AvgHoldTime={en:Avg HoldTime;zh:平均保持时间},  AvgRingTime={en:Avg RingTime;zh:平均振铃时间},  AvgAcwTime={en:Avg AcwTime;zh:平均话后处理时间},  AvgHandleTime={en:Avg HandleTime;zh:平均处理时间},  SvcLevel={en:Svc Level;zh:服务水平},  CallTrans={en:Call Trans;zh:转接呼叫数},  CallTransRate={en:Call TransRate;zh:转接率},  CallConf={en:Call Conf;zh:会议呼叫数},  LoginTime={en:Login Time;zh:总工作时间},  AvailTime={en:Avail Time;zh:总可用时间},  AvailRate={en:Avail Rate;zh:可用率},  Occupancy={en:Occupancy;zh:占用率},  RepDate={en:Report Date;zh:日期},  TrunkIn={en:Trunk In;zh:中继呼入数},  TrunkInAns={en:Trunk InAns;zh:中继呼入应答数}', null, '', '', '', '', '', 'TotalTalkTime=time_sec,  AvgTalkTime=time_sec,  AvgAcdTime=time_sec,  AvgRingTime=time_sec,  AvgAnsTime=time_sec,  AvgHoldTime=time_sec,  AvgAcwTime=time_sec,  AvgHandleTime=time_sec,  LoginTime=time_sec,  AvailTime=time_sec,  AbanRate=0%,  AvailRate=0%,   Occupancy=0%,   CallTransRate=0%,  SvcLevel=0%', '', '', '', 'TimeRange=Time,  PrjId=Project ID,  Skill=Skill', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('stat.skill.report.year', '{zh:技能组呼叫统计报表(年报),en:Skill Statistic Report (Annually)}', 100, '0', 30303000, 24, 1, 15, 15, -1, '', '', 0, 0, 0, '', '', 0, 0, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'vxi_rep..sp_stat_skill_report', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'prjid={en:Project ID;zh:项目},  date_group={en:Group Level;zh:分组类别},  RecDT={en:Date;zh:日期},  Skill={en:Skill;zh:技能组},  CallOffer={en:Call Offer;zh:总呼叫数},  CallAns={en:Call Ans;zh:总应答数},  AnsLess={en:Ans Less;zh:及时应答数},  AnsMore={en:Ans More;zh:超时应答数},  CallAban={en:Call Aban;zh:放弃呼叫数},  AbanRate={en:Aban Rate;zh:放弃率},  AbanSkill={en:Aban Skill;zh:队列放弃数},  AbanAgent={en:Aban Agent;zh:队列放弃数},  AbanLess={en:Aban Less;zh:时限内放弃},  AbanMore={en:Aban More;zh:时限外放弃},  TotalTalkTime={en:Total TalkTime;zh:总通话时间},  AvgTalkTime={en:Avg TalkTime;zh:平均通话时间},  AvgHoldTime={en:Avg HoldTime;zh:平均保持时间},  AvgRingTime={en:Avg RingTime;zh:平均振铃时间},  AvgAcwTime={en:Avg AcwTime;zh:平均话后处理时间},  AvgHandleTime={en:Avg HandleTime;zh:平均处理时间},  SvcLevel={en:Svc Level;zh:服务水平},  CallTrans={en:Call Trans;zh:转接呼叫数},  CallTransRate={en:Call TransRate;zh:转接率},  CallConf={en:Call Conf;zh:会议呼叫数},  LoginTime={en:Login Time;zh:总工作时间},  AvailTime={en:Avail Time;zh:总可用时间},  AvailRate={en:Avail Rate;zh:可用率},  Occupancy={en:Occupancy;zh:占用率},  RepDate={en:Report Date;zh:日期},  TrunkIn={en:Trunk In;zh:中继呼入数},  TrunkInAns={en:Trunk InAns;zh:中继呼入应答数}', null, '', '', '', '', '', 'TotalTalkTime=time_sec,  AvgTalkTime=time_sec,  AvgAcdTime=time_sec,  AvgRingTime=time_sec,  AvgAnsTime=time_sec,  AvgHoldTime=time_sec,  AvgAcwTime=time_sec,  AvgHandleTime=time_sec,  LoginTime=time_sec,  AvailTime=time_sec,  AbanRate=0%,  AvailRate=0%,   Occupancy=0%,   CallTransRate=0%,  SvcLevel=0%', '', '', '', 'YearSch=RepDate,  PrjId=Project ID,  Skill=Skill', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('station', '{zh:计算机设置,en:Computer Setting}', 100, '0', 20300000, 13, 7, 15, 15, -1, 'vxi_sys..station', 'station', 0, 0, null, '', '', 0, 0, null, null, '', 1000, null, 'ext.edit.search.jsp', null, null, 'station.jsp', 'station.jsp', 'station.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', null, null, '', '', '', null, '', '', 'syn=dict:stationip  syn=dict:station  send=VisionEMS  send=VisionLog', 'syn=dict:stationip  syn=dict:station  send=VisionEMS  send=VisionLog', 'syn=dict:stationip  syn=dict:station  send=VisionEMS  send=VisionLog', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', 'sortid=20300000', null, 'station={en:Station;zh:计算机},   Sort={en:Sort;zh:分类},   IP={en:IP Address;zh:IP地址},   ExtIP={en:Ext. IP Address;zh:扩展IP地址},   Enabled={en:Status;zh:状态}', null, null, null, null, null, '', '', null, '', null, 'station=Computer Name, Sort=Sort, IP=IP Address, ExtIP=Ext. IP Address', 'select m.station, m.IP, m.ExtIP, m.enabled from vxi_sys..station m left join sort t on m.sortid = t.sortid', 'select m.station, SortId, IP, ExtIP, Enabled from vxi_sys..station m where m.station = !station', 'select m.station, SortId, IP, ExtIP, Enabled from vxi_sys..station m where m.station = !station', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('store', '{en:Record Storage Setting,zh:记录储存设置}', 100, '0', 20300000, 13, 7, 15, 15, -1, 'vxi_rec..store', 'FtpId', 1, 1, null, '', '', null, null, '', null, '', 1000, 0, 'ext.search.jsp', '', '', 'store.jsp', 'store.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'syn=dict:recstorage  syn=dict:scrstorage  syn=dict:ftpid  send=VisionLog', 'syn=dict:recstorage  syn=dict:scrstorage  syn=dict:ftpid  send=VisionLog', 'syn=dict:recstorage  syn=dict:scrstorage  syn=dict:ftpid  send=VisionLog', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', 'SortId=20300000', '', 'FtpId={en:FtpId;zh:Ftp代码},  SortId={en:Sort;zh:分类代码},  Station={en:Station;zh:站点IP},  Folder={en:Folder;zh:文件夹},  Port={en:Port;zh:端口号},  Drive={en:Drive;zh:盘符},  Priority={en:Priority;zh:优先级},  Username={en:Username;zh:用户名},  Password={en:Password;zh:密码},  AutoBackup={en:Auto Backup;zh:自动备份},  Encry={en:Encry;zh:数据加密},  DestFolder={en:Dest Folder;zh:目的文件夹},  BackupDays={en:Backup Days;zh:备份天数},  BackupTime={en:Backup Time;zh:备份时间},  KeepDays={en:Keep Days;zh:保留天数},  Enabled={en:Enabled;zh:状态}  ', null, null, null, null, null, '', '', null, '', null, 'FtpId=FtpId, Station=Station, Folder=Folder, Port=Port, Drive=Drive', 'select m.FtpId,  m.Station, m.Folder, m.Port, m.Drive,m.Priority,m.Enabled from vxi_rec..store m', 'select m.FtpId, m.SortId, m.Station, m.Folder, m.Port, m.Drive, m.Priority, m.Username, m.Password, m.Encry, m.RealFolder, m.AutoBackup, m.DestFolder, m.BackupDays, m.BackupTime, m.KeepDays, m.Enabled, m.type from vxi_rec..store m where m.FtpId = !FtpId', 'select m.FtpId, m.SortId, m.Station, m.Folder, m.Port, m.Drive, m.Priority, m.Username, m.Password, m.Encry, m.RealFolder, m.AutoBackup, m.DestFolder, m.BackupDays, m.BackupTime, m.KeepDays, m.Enabled, m.type from vxi_rec..store m where m.FtpId = !FtpId', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('test.simplebar', 'Test Simple Bar', 100, null, 60300000, 1, 1, 15, 15, -1, 'vxi_def..jfee', 'id', 1, null, null, null, null, null, null, null, null, null, 1000, 0, 'ext.search.jsp', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'Id=id,  name=name,  addr=addr,  value=value,  date=date', '<fieldx>   <field name="id" owner="master">    <type></type>    <title>id</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey>yes</tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="name" owner="master">    <type></type>    <title>name</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="addr" owner="master">    <type></type>    <title>addr</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen>20</maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="value" owner="master">    <type>bar</type>    <title>value</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>   <field name="date" owner="master">    <type></type>    <title>date</title>    <dict></dict>    <format></format>    <range></range>    <areas></areas>    <size></size>    <maxlen></maxlen>    <defval></defval>    <zero></zero>    <options></options>    <images></images>    <file></file>    <alerts></alerts>    <linkage></linkage>    <unite></unite>    <script></script>    <stat></stat>    <filter></filter>    <sortkey></sortkey>    <tabkey></tabkey>    <subkey></subkey>    <coordinate></coordinate>   </field>  </fieldx>  ', null, null, null, null, null, null, null, null, null, 'Id=id,  name=name,  addr=addr,  value=value,  date=date', 'SELECT Id        ,name        ,addr        ,value        ,date    FROM vxi_def..jfree', 'SELECT Id        ,name        ,addr        ,value        ,date    FROM vxi_def..jfree where id=!id', 'SELECT Id        ,name        ,addr        ,value        ,date    FROM vxi_def..jfree where id=!id', null, null, null, null, null, null, null, null, null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, null, null, null, null, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('trace', 'VisionONE Database Transaction Records', 100, '0', 10000000, 1, 1, 15, 15, -1, 'trace', 'operid', 1, 0, null, '', '', null, null, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', 'trace.jsp', 'trace.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', '', '', 'operid=Record ID, OperTime=Operation Time, Operation=Action', null, null, null, null, null, '', '', null, '', null, 'operid=ID, Operator=Operator Operation=ActionTimeRange=OperTime', 'select m.operid, m.Operator, m.OperTime from trace m', 'select m.operid, m.Operator, m.OperTime, m.Operation from trace m where m.operid = !operid', '', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('trunk', '{zh:中继设备定义, en:VisionONE Trunk Device Setting}', 100, '0', 20100000, 11, 7, 15, 15, -1, 'vxi_sys..trunk', 'trunkid', 0, 0, null, '', '', 0, 0, '', null, '', 1000, 0, 'ext.edit.search.jsp', '', '', 'trunk.jsp', 'trunk.jsp', 'trunk.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'syn=dict:trunk  send=VisionCTI  send=VisionEMS  send=VisionLog', 'syn=dict:trunk  send=VisionCTI  send=VisionEMS  send=VisionLog', 'syn=dict:trunk  send=VisionCTI  send=VisionEMS  send=VisionLog', '', '', '', 'no', '', '', null, null, null, null, null, null, null, null, 0, '', '', 'sortid=20100000', '', 'trunkid={en:Trunk ID; zh:中继代码}, Sort={en:Sort; zh:分类},  TrunkGroup={en:Trunk Group; zh:中继组}, TrunkNum={en:Trunk Member; zh:中继号}, Enabled={en:Status; zh:状态}', null, null, null, null, null, '', '', null, '', null, 'trunkid=Trunk ID, TrunkGroup=Trunk Group', 'select m.trunkid,  m.TrunkGroup, m.TrunkNum,  m.Enabled from vxi_sys..trunk m left join sort t on m.sortid = t.sortid', 'select m.trunkid, m.SortId, m.TrunkGroup, m.TrunkNum, m.Enabled from vxi_sys..trunk m where m.trunkid = !trunkid', 'select m.trunkid, m.SortId, m.TrunkGroup, m.TrunkNum,  m.Enabled from vxi_sys..trunk m where m.trunkid = !trunkid', '', '', '', '', null, '', '', '', '', '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('trunkgrp', '{zh:中继组设置,en:Trunk Group Setting}', 100, '0', 20100000, 11, 7, 15, 15, -1, 'vxi_sys..trunkgroup', 'groupid', 0, 0, null, '', '', 0, 0, null, null, '', 1000, 0, 'ext.edit.search.jsp', null, null, 'trunkgrp.jsp', 'trunkgrp.jsp', 'trunkgrp.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', null, null, '', '', '', null, '', '', 'syn=dict:trunkgroup  send=VisionCTI  send=VisionEMS  send=VisionLog', 'syn=dict:trunkgroup  send=VisionCTI  send=VisionEMS  send=VisionLog', 'syn=dict:trunkgroup  send=VisionCTI  send=VisionEMS  send=VisionLog', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', '', null, 'groupid={en:Trunk Group;zh:中继组},   GroupName={en:Trunk Group Name;zh:中继组名称},   Summary={en:Summary;zh:备注},   Station={en:Station;zh:计算机},   Enabled={en:Status;zh:状态}', null, null, null, null, null, '', '', null, '', null, 'groupid=Trunk Group, GroupName=Trunk Group Name, Station=Station', 'select m.groupid, m.GroupName, m.ftpid,m.voicetype, m.Station, m.Enabled from vxi_sys..trunkgroup m', 'select m.groupid, m.GroupName, m.Summary,  m.Station,m.ftpid,m.voicetype, m.Enabled from vxi_sys..trunkgroup m where m.groupid = !groupid', 'select m.groupid, m.GroupName, m.Summary,m.ftpid,m.voicetype, m.Station, m.Enabled from vxi_sys..trunkgroup m where m.groupid = !groupid', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 1);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('ucd.log', '{zh:统一联络数据,en:Unified Contact Data Log}', 100, '0', 30200000, 21, 1, 15, 15, -1, 'vxi_ucd..ucd', 'ucdid', 1, 1, 0, '', '', 1, null, '', null, '', 1000, 0, 'ext.search.jsp', '', '', '', 'ucd.log.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'no', 'ucdid', 'TimeLen', null, null, null, null, null, null, null, null, 0, '', '', '', 'prjid=prjid', 'ucdid={en:UCDID;zh:统一联络代码},   Calling={en:Calling No.;zh:主叫号码},   Called={en:Called No.;zh:被叫号码},   Answer={en:Answered No;zh:应答号码},   Route={en:Route;zh:路由器},   Skill={en:Skill;zh:技能组},   Trunk={en:Trunk;zh:中继},   StartTime={en:StartTime;zh:开始时间},   TimeLen={en:TimeLen;zh:时长},   Extension={en:Extension;zh:分机},   Agent={en:Agent;zh:座席}', null, null, null, null, null, '', 'TimeLen=timestamp', null, '', null, 'ucdid=UCDID, timerange=StartTime,Calling=Calling No., Called=Called No., Answer=Answered No, Route=Route,agent=Agent,skill=Skill', 'select m.ucdid, m.Calling, m.Called, m.Answer, m.Extension, m.Agent, m.Route, m.Skill, m.Trunk, m.StartTime, m.TimeLen from vxi_ucd..ucd m', 'select m.ucdid, m.ClientId, m.Calling, m.Called, m.Answer, m.Route, m.Skill, m.Trunk, m.StartTime, m.TimeLen, m.Inbound, m.Outbound, m.Extension, m.Agent, m.UcdDate, m.UcdHour, m.PrjId from vxi_ucd..ucd m where m.ucdid = !ucdid', 'select m.ucdid, m.ClientId, m.Calling, m.Called, m.Answer, m.Route, m.Skill, m.Trunk, m.StartTime, m.TimeLen, m.Inbound, m.Outbound, m.Extension, m.Agent, m.UcdDate, m.UcdHour, m.PrjId from vxi_ucd..ucd m where m.ucdid = !ucdid', '', '', '', null, null, null, null, null, null, '', '', '', '', '', 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('ucd.log.com', 'VisionONE Unified Contact Data Log (ComBox)', 100, '0', 30200000, 21, 15, 15, 15, -1, 'vxi_ucd..ucd', 'ucdid', 1, 1, null, '', '', null, null, null, null, '', 1000, 0, 'ext.search.jsp', 'calendar.jsp', 'schcombox.jsp', 'ucd.log.com.jsp', 'ucd.log.com.jsp', 'ucd.log.com.jsp', 'PageBatDel.jsp', '', '', '', '', '', '', '', null, null, '', '', '', null, '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, null, null, null, '', '', '', null, 'ucdid=UCDID , ClientId=Clicent ID, Calling=Calling No., Called=Called No., Answer=Answered No, Route=Route', null, null, null, null, null, '', 'TimeLen=timestamp', null, '', null, 'ucdid=UCDID, TimeRange=StartTime, ClientId=Clicent ID, Calling=Calling No., Called=Called No., Answer=Answered No, Route=Route', 'select m.ucdid, m.Calling, m.Called, m.Answer, m.Extension, m.Agent, m.Route, m.Skill, m.Trunk, m.StartTime, m.TimeLen from vxi_ucd..ucd m', 'select m.ucdid, m.ClientId, m.Calling, m.Called, m.Answer, m.Route, m.Skill, m.Trunk, m.StartTime, m.TimeLen, m.Inbound, m.Outbound, m.Extension, m.Agent, m.UcdDate, m.UcdHour, m.PrjId from vxi_ucd..ucd m where m.ucdid = !ucdid', 'select m.ucdid, m.ClientId, m.Calling, m.Called, m.Answer, m.Route, m.Skill, m.Trunk, m.StartTime, m.TimeLen, m.Inbound, m.Outbound, m.Extension, m.Agent, m.UcdDate, m.UcdHour, m.PrjId from vxi_ucd..ucd m where m.ucdid = !ucdid', '', '', '', '', null, '', '', '', '', '', '', '', '', null, 1, null, null, null, null, null, null, null, null, null, null, null, 0, 0);
INSERT INTO vxi_def..Modules([ModId], [ModName], [ModIndex], [ParentId], [SortId], [CtrlLoc], [VisitPriv], [TabPriv], [SubPriv], [BtnMark], [TabName], [TabKey], [IntTabKey], [AutoTabKey], [Pickup], [SubTabName], [SubTabKey], [IntSubKey], [AutoSubKey], [DataWin], [ModPage], [InitPage], [MaxRows], [SchType], [SchPage], [CalPage], [ComboPage], [EditPage], [ViewPage], [BatAddPage], [BatDelPage], [ViewSP], [InputPage], [SubSchPage], [SubEditPage], [SubViewPage], [SubViewSP], [InitSP], [AckSP], [UnackSP], [SchSP], [SubSchSP], [SubListSP], [SubInsertSP], [OnEnter], [OnLeave], [OnInsert], [OnUpdate], [OnDelete], [OnSubInsert], [OnSubUpdate], [OnSubDelete], [Chart], [AxisX], [AxisY], [UnitX], [UnitY], [Chart1], [AxisY1], [UnitY1], [Chart2], [AxisY2], [UnitY2], [PrintMark], [Summary], [Flow], [Filter], [SortKeys], [Fields], [FieldX], [StatFields], [SchFields], [SubSchFields], [SubListFields], [Relation], [Formats], [PickLinks], [InitSQL], [NewKeySQL], [SchItems], [SchSQL], [ViewSQL], [EditSQL], [InsertSQL], [UpdateSQL], [DeleteSQL], [SubSchItems], [NewSubKeySQL], [SubSchSQL], [SubListSQL], [SubEditSQL], [SubViewSQL], [SubInsertSQL], [SubUpdateSQL], [SubDeleteSQL], [Template], [Prompts], [Visible], [KeyPerson], [KeyGroup], [KeyDept], [SchLocks], [SubLocks], [LstLocks], [SchExTpl], [ExTpl], [SubExTpl], [Show3D], [AddLink], [Acked], [Enabled])  VALUES('users', '{zh:用户帐号设置,en:User Account Setting}', 100, '0', 10200000, 2, 7, 15, 15, -1, 'users', 'userid', 0, 0, null, '', '', 0, 0, '', '', '', 1000, 0, 'ext.skip.search.jsp', '', '', 'users.jsp', 'users.jsp', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', null, null, null, null, null, null, null, null, null, '', '', '', '', 'userid={en:User ID;zh:用户ID},   username={en:User Name;zh:用户名称},   role={en:Role;zh:角色},    rolename={en:Role Name;zh:角色名称},   privilage={en:Privilage;zh:权限},Enabled={en:Status; zh:状态}', '', '', '', '', '', '', '', '', '', '', 'userid=User ID, username=User Name, role=Role,enabled=Status', 'select m.userid, m.username, m.role,  m.enabled from users m, roles r where m.role = r.role', 'select m.*, r.rolename, r.privilege from users m, roles r where m.role = r.role and m.userid = !userid', 'select m.userid, m.username, m.role, m.password,  m.enabled, m.actflag, m.validate from users m where m.userid = !userid', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 1, '', '', '', null, null, null, null, null, null, null, null, 0, 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   Monthly'
Delete from vxi_def..Monthly; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   Nation'
Delete from vxi_def..Nation; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   Node'
Delete from vxi_def..Node; 
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(80, 0, 1, null, '{zh:呼叫完整记录,en:Complete Call Record}', null, 'rep.call.full.record', 'search', null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(80, 1, 1, null, '{zh:呼入详细记录,en: Detailed Inbound Record}', null, 'rep.call.in.record', 'search', null, null, null, null, '', null, 1, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(80, 2, 1, null, '{zh:呼出详细记录,en:Detailed Outbound Record}', null, 'rep.call.out.record', 'search', null, null, null, null, null, null, 2, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(81, 0, 1, null, '{zh:呼叫统计,en:Call Statistics}', null, 'rep.call.stat', 'search', null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(81, 1, 1, null, '{zh:中继呼叫统计,en:Truck Call Statistics}', null, 'rep.call.truck.stat', 'search', null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(81, 2, 1, null, '{zh:电话应答分布,en:Answered Call Distribution}', null, 'rep.call.answerd.dist', 'search', null, null, null, null, null, null, 2, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(81, 3, 1, null, '{zh:呼出电话统计,en:Outbound Statistics}', null, 'rep.call.out.stat', 'search', null, null, null, null, null, null, 3, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(81, 4, 1, null, '{zh:放弃电话统计,en:Missed Call Statistics}', null, 'rep.call.abandon.stat', 'search', null, null, null, null, null, null, 4, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(81, 5, 1, null, '{zh:坐席放弃电话统计,en:Agent Missed Call Statistics}', null, 'rep.call.agent.abandon.stat', 'search', null, null, null, null, null, null, 5, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(82, 0, 1, null, '{zh:坐席呼叫统计,en:Agent Call Statistics}', null, 'rep.call.agent.stat', 'search', null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(82, 1, 1, null, '{zh:坐席状态统计,en:Agent Status Statistics}', null, 'rep.agent.status.stat', 'search', null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(82, 2, 1, null, '{zh:坐席状态时长分布,en:Agent Status Time Long Distribute}', null, 'rep.agent.stat', 'search', null, null, null, null, null, null, 2, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(82, 3, 1, null, '{zh:坐席分机状态分布,en:Agent Extension Status Distribute}', null, 'rep.device.stat.dist', 'search', null, null, null, null, null, null, 3, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(82, 4, 1, null, '{zh:坐席电话来源分布,en:Agent Call Source Distribute}', null, 'rep.call.source.dist', 'search', null, null, null, null, null, null, 4, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(82, 6, 1, null, '{zh:坐席实时状态变化,en:Agent Real Time Status Changes}', null, 'rep.rt.agent.stat', 'search', null, null, null, null, null, null, 6, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(82, 7, 1, null, '{zh:坐席电话接听量分布,en:Agent Answered Distribute}', null, 'rep.call.agent.anwerd.dist', 'search', null, null, null, null, null, null, 7, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(83, 0, 1, null, '{zh:分机呼叫统计,en:Extension Call Statistics}', null, 'rep.ext.call.stat', 'search', null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(83, 1, 1, null, '{zh:分机状态统计,en:Extension State Statistics}', null, 'rep.ext.status.stat', 'search', null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(83, 2, 1, null, '{zh:分机状态变化记录,en:Extension State Change Record}', null, 'rep.ext.status.chg', 'search', null, null, null, null, null, null, 2, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(84, 1, 1, null, '{zh:坐席状态实时采样统计,en:Agetn Status Real Time Sample}', null, 'rep.agent.stat.sample', 'search', null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(84, 2, 1, null, '{zh:坐席状态时序采样统计,en:Agent Status Time Series Sample}', null, 'rep.agent.timing.sample', 'search', null, null, null, null, null, null, 2, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(84, 3, 1, null, '{zh:分机状态实时采样统计,en:Extension Status Real Time Sample}', null, 'rep.ext.rt.sample', 'search', null, null, null, null, null, null, 3, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(84, 4, 1, null, '{zh:分机状态时序采样统计,en:Extension Status Time Series Sample}', null, 'rep.ext.timing.sample', 'search', null, null, null, null, null, null, 4, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(86, 0, 1, null, '{zh:AUX分析,en:AUX Analysis}', null, 'rep.aux.analysis', 'search', null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(86, 1, 1, null, '{zh:人均接听量,en:Average Answered}', null, 'rep.avg.ansvol', 'search', null, null, null, null, null, null, 1, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(86, 4, 1, null, '{zh:KPI综合统计,en:KPI General Statistics}', null, 'rep.kpi.all.stat', 'search', null, null, null, null, null, null, 4, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(86, 6, 1, null, '{zh:员工四率管理,en:Agent Manage(4 Rate)}', null, 'rep.kpi.agent.rate', 'search', null, null, null, null, null, null, 6, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(86, 9, 1, null, '{zh:话务压力分析,en:Telephone Traffic Pressure Analysis}', null, 'rep.callvol.pressurel', 'search', null, null, null, null, null, null, 9, null, null, null, null, null, null, null, null, '', null, null, null, 1);
INSERT INTO vxi_def..Node([FlowId], [NodeId], [NodeType], [SupNode], [NodeName], [NodeIcon], [ModId], [Oper], [ActId], [LinkFile], [LinkTpl], [LinkURL], [DataWin], [ExecSql], [NodeLoc], [AllReady], [PartReady], [NotReady], [SetFlag], [ResetFlag], [Loads], [Saves], [Drops], [Options], [Popup], [Width], [Height], [Enabled])  VALUES(86, 14, 1, null, '{zh:放弃电话等待时长分析,en:Wating Time of Missed Call Analyses}', null, 'rep.call.wait.dist', 'search', null, null, null, null, null, null, 14, null, null, null, null, null, null, null, null, '', null, null, null, 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   Pickup'
Delete from vxi_def..Pickup; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   PrivSort'
Delete from vxi_def..PrivSort; 
INSERT INTO vxi_def..PrivSort([PrivSort], [PrivSortName], [Enabled])  VALUES(0, '{zh:系统环境类, en:Environment Configuration}', 1);
INSERT INTO vxi_def..PrivSort([PrivSort], [PrivSortName], [Enabled])  VALUES(10, '{zh:系统资源类, en:Resource Setting}', 1);
INSERT INTO vxi_def..PrivSort([PrivSort], [PrivSortName], [Enabled])  VALUES(20, '{zh:预测排班类, en:Forecast & Schedule}', 1);
INSERT INTO vxi_def..PrivSort([PrivSort], [PrivSortName], [Enabled])  VALUES(30, '{zh:班表管理类, en:Schedule Tables}', 1);
INSERT INTO vxi_def..PrivSort([PrivSort], [PrivSortName], [Enabled])  VALUES(40, '{zh:现场管理类, en:Schedule Realtime}', 1);
INSERT INTO vxi_def..PrivSort([PrivSort], [PrivSortName], [Enabled])  VALUES(50, '{zh:员工管理类, en:Agent Management}', 1);
INSERT INTO vxi_def..PrivSort([PrivSort], [PrivSortName], [Enabled])  VALUES(60, '{zh:系统保留60, en:Reserved 60}', 1);
INSERT INTO vxi_def..PrivSort([PrivSort], [PrivSortName], [Enabled])  VALUES(70, '{zh:系统保留70, en:Reserved 70}', 1);
INSERT INTO vxi_def..PrivSort([PrivSort], [PrivSortName], [Enabled])  VALUES(80, '{zh:系统保留80, en:Reserved 80}', 1);
INSERT INTO vxi_def..PrivSort([PrivSort], [PrivSortName], [Enabled])  VALUES(90, '{zh:系统保留90, en:Reserved 90}', 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   PrivLoc'
Delete from vxi_def..PrivLoc; 
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(0, 'Loc:00', 0, 0, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(1, 'Loc:01', 0, 1, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(2, 'Loc:02', 0, 2, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(3, 'Loc:03', 0, 3, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(4, 'Loc:04', 0, 4, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(5, 'Loc:05', 0, 5, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(6, 'Loc:06', 0, 6, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(7, 'Loc:07', 0, 7, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(8, 'Loc:08', 0, 8, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(9, 'Loc:09', 0, 9, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(10, 'Loc:10', 10, 0, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(11, 'Loc:11', 10, 1, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(12, 'Loc:12', 10, 2, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(13, 'Loc:13', 10, 3, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(14, 'Loc:14', 10, 4, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(15, 'Loc:15', 10, 5, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(16, 'Loc:16', 10, 6, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(17, 'Loc:17', 10, 7, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(18, 'Loc:18', 10, 8, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(19, 'Loc:19', 10, 9, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(20, 'Loc:20', 20, 0, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(21, 'Loc:21', 20, 1, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(22, 'Loc:22', 20, 2, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(23, 'Loc:23', 20, 3, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(24, 'Loc:24', 20, 4, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(25, 'Loc:25', 20, 5, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(26, 'Loc:26', 20, 6, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(27, 'Loc:27', 20, 7, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(28, 'Loc:28', 20, 8, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(29, 'Loc:29', 20, 9, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(30, 'Loc:30', 30, 0, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(31, 'Loc:31', 30, 1, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(32, 'Loc:32', 30, 2, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(33, 'Loc:33', 30, 3, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(34, 'Loc:34', 30, 4, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(35, 'Loc:35', 30, 5, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(36, 'Loc:36', 30, 6, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(37, 'Loc:37', 30, 7, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(38, 'Loc:38', 30, 8, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(39, 'Loc:39', 30, 9, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(40, 'Loc:40', 40, 0, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(41, 'Loc:41', 40, 1, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(42, 'Loc:42', 40, 2, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(43, 'Loc:43', 40, 3, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(44, 'Loc:44', 40, 4, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(45, 'Loc:45', 40, 5, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(46, 'Loc:46', 40, 6, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(47, 'Loc:47', 40, 7, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(48, 'Loc:48', 40, 8, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(49, 'Loc:49', 40, 9, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(50, 'Loc:50', 50, 0, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(51, 'Loc:51', 50, 1, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(52, 'Loc:52', 50, 2, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(53, 'Loc:53', 50, 3, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(54, 'Loc:54', 50, 4, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(55, 'Loc:55', 50, 5, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(56, 'Loc:56', 50, 6, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(57, 'Loc:57', 50, 7, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(58, 'Loc:58', 50, 8, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(59, 'Loc:59', 50, 9, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(60, 'Loc:60', 60, 0, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(61, 'Loc:61', 60, 1, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(62, 'Loc:62', 60, 2, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(63, 'Loc:63', 60, 3, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(64, 'Loc:64', 60, 4, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(65, 'Loc:65', 60, 5, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(66, 'Loc:66', 60, 6, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(67, 'Loc:67', 60, 7, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(68, 'Loc:68', 60, 8, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(69, 'Loc:69', 60, 9, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(70, 'Loc:70', 70, 0, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(71, 'Loc:71', 70, 1, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(72, 'Loc:72', 70, 2, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(73, 'Loc:73', 70, 3, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(74, 'Loc:74', 70, 4, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(75, 'Loc:75', 70, 5, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(76, 'Loc:76', 70, 6, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(77, 'Loc:77', 70, 7, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(78, 'Loc:78', 70, 8, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(79, 'Loc:79', 70, 9, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(80, 'Loc:80', 80, 0, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(81, 'Loc:81', 80, 1, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(82, 'Loc:82', 80, 2, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(83, 'Loc:83', 80, 3, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(84, 'Loc:84', 80, 4, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(85, 'Loc:85', 80, 5, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(86, 'Loc:86', 80, 6, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(87, 'Loc:87', 80, 7, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(88, 'Loc:88', 80, 8, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(89, 'Loc:89', 80, 9, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(90, 'Loc:90', 90, 0, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(91, 'Loc:91', 90, 1, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(92, 'Loc:92', 90, 2, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(93, 'Loc:93', 90, 3, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(94, 'Loc:94', 90, 4, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(95, 'Loc:95', 90, 5, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(96, 'Loc:96', 90, 6, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(97, 'Loc:97', 90, 7, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(98, 'Loc:98', 90, 8, 1);
INSERT INTO vxi_def..PrivLoc([PrivLoc], [PrivName], [PrivSort], [SubIdx], [Enabled])  VALUES(99, 'Loc:99', 90, 9, 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   Query'
Delete from vxi_def..Query; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   Roles'
Delete from vxi_def..Roles; 
INSERT INTO vxi_def..Roles([Role], [RoleName], [Privilege], [Summary], [RootSort], [RootFile], [RootURL], [RecPriv], [ExtInfo], [RecPerson], [RecGroup], [RecDept], [RoleType], [MacMatch], [HideSorts], [Acked], [Enabled])  VALUES(1, 'admin', '0FFF0000000FFFFF0F000000000F00F0F00000000FFFF000000000000000000F0F000000000000000000000000F000000000', '系统操作员', null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Roles([Role], [RoleName], [Privilege], [Summary], [RootSort], [RootFile], [RootURL], [RecPriv], [ExtInfo], [RecPerson], [RecGroup], [RecDept], [RoleType], [MacMatch], [HideSorts], [Acked], [Enabled])  VALUES(101, 'browser', '0100000000001730000001010000000000000000000000000000000000000000000000000000000000000000000000000000', '普通操作员', null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Roles([Role], [RoleName], [Privilege], [Summary], [RootSort], [RootFile], [RootURL], [RecPriv], [ExtInfo], [RecPerson], [RecGroup], [RecDept], [RoleType], [MacMatch], [HideSorts], [Acked], [Enabled])  VALUES(102, 'manager', '0FFF0000000FFFFF0F000000000F00F0F00000000FF0F000000000000000000F0F000000000000000000000000F000000000', '设备管理员', null, '', null, null, 'projectid={projectid},agentlist={agentlist},skilllist={skilllist},tasklist={tasklist},grouplist={grouplist},extlist={extlist}', null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Roles([Role], [RoleName], [Privilege], [Summary], [RootSort], [RootFile], [RootURL], [RecPriv], [ExtInfo], [RecPerson], [RecGroup], [RecDept], [RoleType], [MacMatch], [HideSorts], [Acked], [Enabled])  VALUES(103, 'system', '0ff00f00000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000', '系统管理员', null, null, null, null, null, null, null, null, null, null, null, null, 1);
INSERT INTO vxi_def..Roles([Role], [RoleName], [Privilege], [Summary], [RootSort], [RootFile], [RootURL], [RecPriv], [ExtInfo], [RecPerson], [RecGroup], [RecDept], [RoleType], [MacMatch], [HideSorts], [Acked], [Enabled])  VALUES(112, 'qa', '010000000000000000000E000000000000000000001000000000000000000000000000000000000000000000000000000000', 'QA', null, null, null, null, null, null, null, null, null, null, null, null, 1);
    end;
  
    If @Error=0 begin 
print 'Table Name:   SheetID'
Delete from vxi_def..SheetID; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   State'
Delete from vxi_def..State; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   Strings'
Delete from vxi_def..Strings; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   Tables'
Delete from vxi_def..Tables; 
INSERT INTO vxi_def..Tables([TabName], [Summary])  VALUES('*', 'All');
    end;
  
    If @Error=0 begin 
print 'Table Name:   Tags'
Delete from vxi_def..Tags; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   TempItems'
Delete from vxi_def..TempItems; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   Template'
Delete from vxi_def..Template; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   TempRep'
Delete from vxi_def..TempRep; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   TplFileLib'
Delete from vxi_def..TplFileLib; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   Trace'
Delete from vxi_def..Trace; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   TreeDef'
Delete from vxi_def..TreeDef; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   TreeItem'
Delete from vxi_def..TreeItem; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   Users'
Delete from vxi_def..Users; 
INSERT INTO vxi_def..Users([UserId], [UserName], [Password], [Role], [DeptId], [Style], [Acked], [Enabled], [LastDate], [Validate], [ErrTimes], [Locked], [Mac], [actflag])  VALUES('admin', 'admin', 'admin', 1, null, null, null, 1, 20110810, 90, null, null, null, 0);
    end;
  
    If @Error=0 begin 
print 'Table Name:   UserStyle'
Delete from vxi_def..UserStyle; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   version'
Delete from vxi_def..version; 
INSERT INTO vxi_def..version([version], [verdate])  VALUES('3.5.7.14', 20110816);
    end;
  
    If @Error=0 begin 
print 'Table Name:   ChType'
Delete from vxi_sys..ChType; 
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(1, 'IVR');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(2, 'VRS');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(4, 'PDS');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(16, 'IVR');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(17, 'IVR-Trunk');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(18, 'IVR-Conf');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(19, 'IVR-Ext');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(20, 'IVR-IP');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(32, 'VRS');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(33, 'VRS-Trunk');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(34, 'VRS-Conf');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(35, 'VRS-Ext');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(36, 'VRS-IP');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(64, 'PDS');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(65, 'PDS-Trunk');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(66, 'PDS-Conf');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(67, 'PDS-Ext');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(68, 'PDS-IP');
    end;
  
    If @Error=0 begin 
print 'Table Name:   DataType'
Delete from vxi_sys..DataType; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   DevType'
Delete from vxi_sys..DevType; 
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(2, 'Agent');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(18, 'Agent Group');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(7, 'Audio');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(1, 'Extension');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(17, 'Extension Group');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(6, 'External');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(4, 'Route');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(3, 'Skill');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(5, 'Trunk');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(21, 'Trunk Group');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(0, 'Unknown');
    end;
  
    If @Error=0 begin 
print 'Table Name:   VoiceType'
Delete from vxi_sys..VoiceType; 
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(1, 'VCE', 'vce', 16, 0, 'VCE File, .vce', 1);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(2, 'VOX', 'vox', 16, 0, 'VOX File, .vox', 1);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(3, 'MP3', 'mp3', 8, 0, 'MP3 File, mp3', 1);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(4, 'WAV', 'wav', 8, 0, 'WAV File, .wav', 1);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(5, 'G729A', 'g729a', 16, 4, 'G729A File, .g729a', 1);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(6, 'VXI', 'vxi', 16, 4, 'VXI Compress File, .vxi', 1);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(7, 'g711u', 'g711', 8, 0, 'G711U  File, .g711', 1);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(8, 'alaw', 'alaw', 8, 0, 'ALAW  File, .alaw', 0);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(9, 'g723', 'g723', 16, 0, 'G723 File, .g723', 0);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(10, 'g726', 'g726', 16, 0, 'G726 File, .g726', 0);
    end;
  
    If @Error=0 begin 
print 'Table Name:   PrjItemType'
Delete from vxi_sys..PrjItemType; 
INSERT INTO vxi_sys..PrjItemType([Type], [TypeName])  VALUES(1, 'Agent');
INSERT INTO vxi_sys..PrjItemType([Type], [TypeName])  VALUES(2, 'Extension');
INSERT INTO vxi_sys..PrjItemType([Type], [TypeName])  VALUES(3, 'Skill');
INSERT INTO vxi_sys..PrjItemType([Type], [TypeName])  VALUES(4, 'Route');
INSERT INTO vxi_sys..PrjItemType([Type], [TypeName])  VALUES(5, 'Trunk Group');
INSERT INTO vxi_sys..PrjItemType([Type], [TypeName])  VALUES(6, 'Calling No.');
INSERT INTO vxi_sys..PrjItemType([Type], [TypeName])  VALUES(7, 'Called No.');
    end;
  
    If @Error=0 begin 
print 'Table Name:   GroupType'
Delete from vxi_sys..GroupType; 
INSERT INTO vxi_sys..GroupType([GroupType], [TypeName])  VALUES(0, 'Unknown');
INSERT INTO vxi_sys..GroupType([GroupType], [TypeName])  VALUES(1, 'Agent Group');
INSERT INTO vxi_sys..GroupType([GroupType], [TypeName])  VALUES(2, 'Extension Group');
INSERT INTO vxi_sys..GroupType([GroupType], [TypeName])  VALUES(3, 'Channel Group');
INSERT INTO vxi_sys..GroupType([GroupType], [TypeName])  VALUES(4, 'Trunk Group');
INSERT INTO vxi_sys..GroupType([GroupType], [TypeName])  VALUES(5, 'Station Group');
    end;

  
    If @Error=0 begin 
print 'Table Name:   FaxCategory'
Delete from vxi_ivr..FaxCategory; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   FaxLevel'
Delete from vxi_ivr..FaxLevel; 
INSERT INTO vxi_ivr..FaxLevel([LevelID], [TryTimes], [LevelDesc])  VALUES(1, 2, 'normal');
INSERT INTO vxi_ivr..FaxLevel([LevelID], [TryTimes], [LevelDesc])  VALUES(2, 3, 'important');
INSERT INTO vxi_ivr..FaxLevel([LevelID], [TryTimes], [LevelDesc])  VALUES(3, 5, 'very important');
    end;
  
    If @Error=0 begin 
print 'Table Name:   FaxReason'
Delete from vxi_ivr..FaxReason; 
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(0, 'Normal', '正常');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(1, 'Invalid Time Range', '非法时间范围(超过预定结束时间)');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(2, 'Overrun Max Trytimes', '超过最大发送次数');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(3, 'No Local FAX File', '本地FAX文件未找到');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(4, 'Conver Fail', '转化TIF失败，超时');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(5, 'Printer Fail', '打印机启动失败');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(6, 'No Local TIF File', '本地接收TIF文件未找到');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(7, 'Conver Dest Format Fail', '转化为目的文件格式失败');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(101, 'CFR_NO_DIAL_TONE', '没有拨号音');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(102, 'CFR_INVALID_DNIS', '非法被叫');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(103, 'CFR_RMT_BUSY', '远端忙');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(104, 'CFR_TIMEOUT', '超时');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(105, 'CFR_NO_ANSWER', '无应答');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(106, 'CFR_TRUNK_BUSY', '中继忙');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(107, 'CFR_ERROR', '错误');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(108, 'CFR_RMT_RELEASED', '远端释放');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(109, 'CFR_RELEASED', '本端释放');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(110, 'CFR_NO_AVALABLE', '不可用');
    end;
  
    If @Error=0 begin 
print 'Table Name:   FaxStatus'
Delete from vxi_ivr..FaxStatus; 
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(1, 'Send_Fax', '待发送传真');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(2, 'Send_Sending', '发送传真中');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(3, 'Send_Fail', '发送传真失败');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(4, 'Send_Succ', '发送传真成功');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(5, 'Send_Fin_Succ', '发送传真最终成功');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(6, 'Send_Fin_Fail', '发送传真最终失败');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(11, 'Rece_New', '新收到传真');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(12, 'Rece_Notify', '已经通知程序');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(13, 'Rece_Fin_Succ', '接收传真最终成功');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(14, 'Rece_Fin_Fail', '接收传真最终失败');
    end;
  
    If @Error=0 begin 
print 'Table Name:   IvrNodeResult'
Delete from vxi_ivr..IvrNodeResult; 
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(0, 'NORMAL', '节点正常结束');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(2, 'TERM_DTMF', '用户安按键终止');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(3, 'TERM_MAX_DIGITS', '最大按键数终止');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(4, 'TERM_END_DIGIT', '终止键终止');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(5, 'TERM_STOPPED', '主动停止终止');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(6, 'TERM_RMT_RELEASED', '远端挂机终止');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(7, 'TERM_TIMEOUT', '超时终止');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(8, 'TERM_MAX_TIME', '到达最大时长终止');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(9, 'TERM_MAX_SILENCE', '到达最大静音时长终止');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(10, 'TERM_ERROR', '遇到错误终止');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(11, 'TERM_RELEASED', '呼叫释放导致终止');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(101, 'CFR_NO_DIAL_TONE', '没有拨号音');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(102, 'CFR_INVALID_DNIS', '非法被叫');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(103, 'CFR_RMT_BUSY', '远端忙');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(104, 'CFR_TIMEOUT', '超时');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(105, 'CFR_NO_ANSWER', '无应答');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(106, 'CFR_TRUNK_BUSY', '中继忙');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(107, 'CFR_ERROR', '错误');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(108, 'CFR_RMT_RELEASED', '远端释放');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(109, 'CFR_RELEASED', '本端释放');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(110, 'CFR_NO_AVALABLE', '不可用');
    end;
  
    If @Error=0 begin 
print 'Table Name:   IvrNodeType'
Delete from vxi_ivr..IvrNodeType; 
    end;
  
    If @Error=0 begin 
print 'Table Name:   VoiceStatus'
Delete from vxi_ivr..VoiceStatus; 
INSERT INTO vxi_ivr..VoiceStatus([StatusID], [Description])  VALUES(1, '新留言');
INSERT INTO vxi_ivr..VoiceStatus([StatusID], [Description])  VALUES(2, '已听留言');
INSERT INTO vxi_ivr..VoiceStatus([StatusID], [Description])  VALUES(3, '已删除');
    end;

  
    If @Error=0 begin 
print 'Table Name:   StoreType'
Delete from vxi_rec..StoreType; 
INSERT INTO vxi_rec..StoreType([StoreType], [TypeName])  VALUES(1, 'VRS');
INSERT INTO vxi_rec..StoreType([StoreType], [TypeName])  VALUES(2, 'TRS');
INSERT INTO vxi_rec..StoreType([StoreType], [TypeName])  VALUES(3, 'VRS & TRS');
INSERT INTO vxi_rec..StoreType([StoreType], [TypeName])  VALUES(4, 'Email');
INSERT INTO vxi_rec..StoreType([StoreType], [TypeName])  VALUES(128, 'AutomaticUpdates');
    end;
  
    If @Error=0 begin 
print 'Table Name:   TaskType'
Delete from vxi_rec..TaskType; 
    end;

  
    If @Error=0 begin 
print 'Table Name:   stat_param'
Delete from vxi_ucd..stat_param; 
    end;



	--end 
	ALTER table VXI_DEF..FLOW enable TRIGGER tr_flow_iu;
	    
    if @Error = 0 begin
		COMMIT tran
	end
	else begin
		rollback tran
	end

	select case @Error when 0 then 'Success!' else 'Fault!' end Result
	return @Error

end try
begin CATCH
	if @@trancount > 0 rollback tran
	print '[sp_vxidef_setup](vxi_def数据库信息初始化失败！)'
	print Error_Message()
	return -1
end catch




GO
/****** Object:  UserDefinedFunction [dbo].[avg_float]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[avg_float](@sumval numeric(38, 6), @numval numeric(38, 6), @dec int)
RETURNS float AS  
BEGIN
	return case when @numval != 0 then Round(@sumval / @numval, @dec)
				else 0
		   end
END

GO
/****** Object:  UserDefinedFunction [dbo].[avg_int]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[avg_int](@sumval int, @numval int)
RETURNS int AS  
BEGIN
	return case when @numval != 0 then Round(cast(@sumval as numeric(38, 6)) / @numval, 0)
				else 0
		   end
END

GO
/****** Object:  UserDefinedFunction [dbo].[avg_str]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--print '[' + dbo.avg_str(1, 6, 0) + ']'

CREATE FUNCTION [dbo].[avg_str](@sumval int, @numval int, @is_percent int)
RETURNS varchar(40) AS  
BEGIN 
	
	declare @result varchar(40)

	if @numval <> 0 begin

		if isnull(@is_percent, 0) = 0 begin --非百分比
			--set @result = cast(Round(cast(@sumval as numeric(38, 6)) / @numval, 2) as varchar(40))
			--set @result = left(@result, len(@result) - 4)
			set @result = ltrim(str(Round(cast(@sumval as numeric(38, 6)) / @numval, 2), 40, 2))
		end
		else begin
			--set @result = cast(Round(cast(@sumval as numeric(38, 6)) / @numval * 100, 2) as varchar(40))
			--set @result = left(@result, len(@result) - 4) + '%'
			set @result = ltrim(str(Round(cast(@sumval as numeric(38, 6)) / @numval * 100, 2), 40, 2)) + '%'
		end

	end
	else begin
		return ''
	end
	
	return @result
END


GO
/****** Object:  UserDefinedFunction [dbo].[datediff_ms]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2008-03-04>
-- Description:	相当于datediff(ms, @StartDate, @EndDate)，无溢出
-- =============================================
CREATE FUNCTION [dbo].[datediff_ms](@StartDate datetime, @EndDate datetime)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	declare @DiffHour int, @Result int
	-- 获取小时差
	set @DiffHour = datediff(Hour, @StartDate, @EndDate)

	-- 596.xx小时超过了(2^31-1)毫秒数
	set @Result =
		case when @DiffHour is null then null
			 when @DiffHour < 596 then datediff(ms, @StartDate, @EndDate) 
			 else 2147483647
		end

	return @Result
END


GO
/****** Object:  UserDefinedFunction [dbo].[datetime_to_datestr]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[datetime_to_datestr] (@dt datetime)  
RETURNS varchar(10) AS  
BEGIN 
	return convert(varchar(10), @dt, 120)
END


GO
/****** Object:  UserDefinedFunction [dbo].[datetime_to_timestr]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[datetime_to_timestr] (@dt datetime)
RETURNS varchar(8) AS
BEGIN 
	return convert(varchar(8), @dt, 108)
END



GO
/****** Object:  UserDefinedFunction [dbo].[func_day]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[func_day] (@date datetime)  
RETURNS int AS  
BEGIN 
	return (year(@date) * 10000 + month(@date) * 100 + day(@date))
END



GO
/****** Object:  UserDefinedFunction [dbo].[func_get_calendargetlunar]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =========================================================
-- Author:		zhangsl
-- Create date: 2008-10-23
-- Description:	根据公历日期查其对应的农历日期
-- =========================================================
CREATE  FUNCTION  [dbo].[func_get_calendargetlunar](@solarDay  DATETIME)          
RETURNS varchar(8)     
AS          
BEGIN          
	DECLARE  @solData  int          
	DECLARE  @offset  int          
	DECLARE  @iLunar  int          
	DECLARE  @i  INT            
	DECLARE  @j  INT            
	DECLARE  @yDays  int          
	DECLARE  @mDays  int          
	DECLARE  @mLeap  int          
	DECLARE  @mLeapNum  int          
	DECLARE  @bLeap  smallint          
	DECLARE  @temp  int          
	 
	DECLARE  @YEAR  INT            
	DECLARE  @MONTH  INT          
	DECLARE  @DAY  INT          
	     
	DECLARE  @OUTPUTDATE  varchar(8)          
	
	--保证传进来的日期是不带时间          
	SET  @solarDay = convert(varchar(8), @solarDay, 112)         
	SET  @solarDay=convert(varchar, @solarDay, 21)
	SET  @offset=CAST(@solarDay-'1900-01-30'  AS  INT)      
	
	 
	--确定农历年开始          
	SET  @i=1900          
	--SET  @offset=@solData          
	WHILE  @i<2050  AND  @offset>0          
	BEGIN          
		SET  @yDays=348          
		SET  @mLeapNum=0          
		SELECT  @iLunar=dataInt  FROM  CalendarSolarData  WHERE  xYear=@i          
		 
		--传回农历年的总天数          
		SET  @j=32768          
		WHILE  @j>8          
		BEGIN          
		   IF  @iLunar  &  @j  >0          
		       SET  @yDays=@yDays+1          
		   SET  @j=@j/2          
		END          
		 
		--传回农历年闰哪个月  1-12  ,  没闰传回  0          
		SET  @mLeap  =  @iLunar  &  15          
		 
		--传回农历年闰月的天数  ,加在年的总天数上          
		IF  @mLeap  >  0          
		BEGIN          
		   IF  @iLunar  &  65536  >  0          
		       SET  @mLeapNum=30          
		   ELSE            
		       SET  @mLeapNum=29          
		 
		   SET  @yDays=@yDays+@mLeapNum          
		END          
		         
		SET  @offset=@offset-@yDays          
		SET  @i=@i+1          
	END          
	     
	IF  @offset  <=  0          
	BEGIN          
		SET  @offset=@offset+@yDays          
		SET  @i=@i-1          
	END          
	--确定农历年结束              
	SET  @YEAR=@i          
	
	--确定农历月开始          
	SET  @i  =  1          
	SELECT  @iLunar=dataInt  FROM  CalendarSolarData  WHERE  xYear=@YEAR      
	
	--判断那个月是润月          
	SET  @mLeap  =  @iLunar  &  15          
	SET  @bLeap  =  0        
	
	WHILE  @i  <  13  AND  @offset  >  0          
	BEGIN          
		--判断润月          
		SET  @mDays=0          
		IF  (@mLeap  >  0  AND  @i  =  (@mLeap+1)  AND  @bLeap=0)          
		BEGIN--是润月          
		   SET  @i=@i-1          
		   SET  @bLeap=1          
		   --传回农历年闰月的天数          
		   IF  @iLunar  &  65536  >  0          
		       SET  @mDays  =  30          
		   ELSE            
		       SET  @mDays  =  29          
		END          
		ELSE          
		--不是润月          
		BEGIN          
		   SET  @j=1          
		   SET  @temp  =  65536            
		   WHILE  @j<=@i          
		   BEGIN          
		       SET  @temp=@temp/2          
		       SET  @j=@j+1          
		   END          
		 
		   IF  @iLunar  &  @temp  >  0          
		       SET  @mDays  =  30          
		   ELSE          
		       SET  @mDays  =  29          
		END          
	     
		--解除闰月      
		IF  @bLeap=1  AND  @i=  (@mLeap+1)      
		   SET  @bLeap=0      
		
		SET  @offset=@offset-@mDays          
		SET  @i=@i+1          
	END          
	 
	IF  @offset  <=  0          
	BEGIN          
		SET  @offset=@offset+@mDays          
		SET  @i=@i-1          
	END          
	
	--确定农历月结束              
	SET  @MONTH=@i      
	 
	--确定农历日结束              
	SET  @DAY=@offset          
	 
	SET  @OUTPUTDATE=CAST(@YEAR  AS  VARCHAR(4))+
			+Case When @Month<10 Then '0' Else '' End + CAST(@MONTH  AS  VARCHAR(2))+
			+Case When @Day<10   Then '0' Else '' End + CAST(@DAY  AS  VARCHAR(2))

	RETURN  @OUTPUTDATE      
END        
GO
/****** Object:  UserDefinedFunction [dbo].[func_get_calendarsolarterm]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[func_get_calendarsolarterm](@Year int , @n int )
returns int 
/* 把当天和1900年1月0日（星期日）的差称为积日，那么第y年（1900年算第0年）第x 个节气的积日是 
 F = 365.242 * y + 6.2 + 15.22 * x - 1.9 * sin(0.262 * x) 
节气:
 0 小寒  腊月 6  清明 三月 12 小暑 六月 18 寒露 九月
 1 大寒  腊月 7  谷雨 三月 13 大暑 六月 19 霜降 九月
 2 立春  正月 8  立夏 四月 14 立秋 七月 20 立冬 十月
 3 雨水  正月 9  小满 四月 15 处暑 七月 21 小雪 十月
 4 惊蛰  二月 10 芒种 五月 16 白露 八月 22 大雪 冬月
 5 春分  二月 11 夏至 五月 17 秋分 八月 23 冬至 冬月
*/
as 
begin 
	declare @i int 
	select @i=(365.242 * (@Year-1900) + 6.2 + 15.22 * @n - 1.9 * sin(0.262 * @n)-25567)	
	return dbo.func_day(DateAdd(Day,@i-1,'1970-1-1'))
end


--select dbo.[func_get_calendarsolarterm](2011,23)
GO
/****** Object:  UserDefinedFunction [dbo].[func_month]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[func_month] ()
RETURNS int
WITH EXECUTE AS CALLER
AS
BEGIN
  declare @month int, @today datetime
  select @today = getdate()
  select @month = datepart(month, @today)
  return(@month)
END

GO
/****** Object:  UserDefinedFunction [dbo].[func_month_first]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[func_month_first] (@date datetime)
RETURNS int AS  
BEGIN 
	return (year(@date) * 10000 + month(@date) * 100 + 1)
END



GO
/****** Object:  UserDefinedFunction [dbo].[func_month_last]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[func_month_last] (@date datetime)
RETURNS int AS  
BEGIN 
	declare @first datetime, @last datetime
	set @first = str(year(@date) * 10000 + month(@date) * 100 + 1)
	set @last = dateadd(dd, -1, dateadd(mm, 1, @first))
	return (year(@last) * 10000 + month(@last) * 100 + day(@last))
END


GO
/****** Object:  UserDefinedFunction [dbo].[func_paramobj_get]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===============================================
-- Author: wei.jia@vxichina.com
-- Create date: Dec 7, 2007
-- Description:	To get a parameter from given xml;
-- used by CallBack functions.
-- ===============================================

CREATE FUNCTION [dbo].[func_paramobj_get]
(
	@param xml, 
	@propname varchar(2000)
)
RETURNS varchar(8000)
AS
BEGIN

	declare @propvalue varchar(8000);
	set @propvalue = @param.value('(/root/*[@id=sql:variable("@propname")])[1]', 'varchar(8000)');
	return @propvalue;
	
END

GO
/****** Object:  UserDefinedFunction [dbo].[func_paramobj_set]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===============================================
-- Author: wei.jia@vxichina.com
-- Create date: Dec 7, 2007
-- Description:	To set a parameter to given xml;
-- used by CallBack functions.
-- ===============================================

CREATE FUNCTION [dbo].[func_paramobj_set]
(
	@param xml, 
	@propname varchar(2000),
	@propvalue varchar(8000)
)
RETURNS xml
AS
BEGIN

	if @param is null set @param = '<root/>';
	set @param.modify('delete (/root/param[@id=sql:variable("@propname")])');
	set @param.modify('insert <param id="{sql:variable("@propname")}">{sql:variable("@propvalue")}</param> into /*[1]');
	return @param;
	
END


GO
/****** Object:  UserDefinedFunction [dbo].[func_set_holiday]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =========================================================
-- Author:		zhangsl
-- Create date: 2008-10-10
-- Description:	对国定假日，确定其假日代码（在defitem中定义的值）
-- Example: select dbo.func_set_holiday(20100101)
-- =========================================================
CREATE function [dbo].[func_set_holiday] (@date int)
returns tinyint
as
/*
kyeid = 12
0	元旦
1	春节(初一)
2	春节(初二)
3	春节(初三)
4	清明
5	劳动节
6	端午节
7	中秋节
8	国庆节(1)
9	国庆节(2)
10	国庆节(3)
*/
begin
	declare @R tinyint, @Year int, @xDate int, @LunarDate int, @LunarDT int
	
	set @Year = left(cast(@date as varchar(8)),4)
	set @xDate = Cast(SubString(convert(varchar(8),@date),5,8) as int)
	--农历日期
	set @LunarDate = Cast(Right(dbo.func_get_calendargetlunar(str(@date)),4) as int) 
	
 
	set @R = null
	--国定假日（公历）
	select @R = HolId from Holidays where HolType = 1 and RecDate = @xDate and Enabled = 1
	set @LunarDT = dbo.func_get_calendargetlunar(str(@date))
	
	if not exists(select 1 from wfm_def..Calendar
					where CalDate < @date 
						and @LunarDT = dbo.func_get_calendargetlunar(str(CalDate))
						and CalDate >= convert(varchar(8),dateadd(m, -3, convert(datetime, str(@date))), 112)) begin
		-- 过滤闰月农历节日（如2009年端午节[20090528/20090627]）
		--国定假日（农历)
		select @R = HolId from Holidays where HolType = 2 and RecDate = @LunarDate and Enabled = 1
	end
	
	--国定假日（农历节气)
	select @R = HolId from Holidays where HolType = 3 and Enabled = 1 and @date = dbo.func_get_calendarsolarterm(@Year, RecDate)	
		
	
	return @R 	
end

GO
/****** Object:  UserDefinedFunction [dbo].[func_set_vacation]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =========================================================
-- Author:		zhangsl
-- Create date: 2008-10-10
-- Description:	根据日期，获取假期性质（0-工作日|1-双休日|2-国定假日）
-- =========================================================
CREATE FUNCTION [dbo].[func_set_vacation](@date int)
returns tinyint
as
begin
	declare @iWeekend tinyint, @iHoliday tinyint, @Year int, @xDate int, @LunarDate int, @LunarDT int
	
	set @Year = left(cast(@date as varchar(8)),4)
	set @xDate = Cast(SubString(convert(varchar(8),@date),5,8) as int)
	--农历日期
	set @LunarDate = Cast(Right(dbo.func_get_calendargetlunar(str(@date)),4) as int) 
	set @LunarDT = dbo.func_get_calendargetlunar(str(@date))
	select @iWeekend = 0, @iHoliday = 0
	
	--国定假日（公历）
	if exists(select 1 from HolidayDef where HolType = 1 and RecDate = @xDate and Enabled = 1) begin
		set @iHoliday = @iHoliday + 2
	end

	--国定假日（农历节气）
	if exists(select 1 from HolidayDef where HolType = 3 and Enabled = 1 and @date = dbo.func_get_calendarsolarterm(@Year, RecDate)) begin
		set @iHoliday = @iHoliday + 2
	end
	else begin
		-- 国定假日（农历）
		-- 过滤闰月农历节日（如 2009 年端午节 [20090528 / 20090627]）
		if exists(select 1 from HolidayDef where HolType = 2 and Enabled = 1 and RecDate = @LunarDate)
			and not exists(select 1 from wfm_def..Calendar
				where CalDate < @date 
					and @LunarDT = dbo.func_get_calendargetlunar(str(CalDate))
					and CalDate >= convert(varchar(8),dateadd(m, -3, convert(datetime, str(@date))), 112))
		begin
			set @iHoliday = @iHoliday + 2
		end
	end

	if (datepart(weekday, str(@date)) - 1) in (0,6) begin
		set @iWeekend = 1
	end
	
	return @iWeekend + @iHoliday	
end

GO
/****** Object:  UserDefinedFunction [dbo].[func_time]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[func_time] (@date datetime)  
RETURNS int AS  
BEGIN 
	return (datepart(hour, @date) * 10000 + datepart(minute, @date) * 100 + datepart(second, @date))
END


GO
/****** Object:  UserDefinedFunction [dbo].[func_today]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[func_today] ()
RETURNS int AS  
BEGIN 
	return year(getdate()) * 10000 + month(getdate()) * 100 + day(getdate())
END


GO
/****** Object:  UserDefinedFunction [dbo].[func_tomorrow]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[func_tomorrow] (@date datetime)
RETURNS int AS  
BEGIN 
	declare @day datetime
	set @date = dateadd(day, 1, @date)
	return (year(@date) * 10000 + month(@date) * 100 + day(@date))
END


GO
/****** Object:  UserDefinedFunction [dbo].[func_week_first]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--返回日期所在周的第一天的日期
CREATE  FUNCTION [dbo].[func_week_first] (@date datetime)
RETURNS INT AS
BEGIN 
	DECLARE	@DateTime DATETIME
	
	SET @DateTime = convert(varchar(8), @Date, 112)
	
	SET @DateTime = DATEADD(DAY, DATEPART(weekday, @DateTime)*(-1) + 1, @DateTime)
	
	RETURN YEAR(@DateTime) *10000 + MONTH(@DateTime)*100 + DAY(@DateTime)

END

                                         

GO
/****** Object:  UserDefinedFunction [dbo].[func_weekday]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[func_weekday] ()
RETURNS int
WITH EXECUTE AS CALLER
AS
BEGIN
  declare @weekday int, @today datetime
  select @today = getdate()
  select @weekday = datepart(weekday, @today)
  return(@weekday) - 1
END

GO
/****** Object:  UserDefinedFunction [dbo].[func_year_first]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[func_year_first] (@date datetime)  
RETURNS int AS  
BEGIN 
	return (year(@date) * 10000 + 101)
END


GO
/****** Object:  UserDefinedFunction [dbo].[func_yesterday]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[func_yesterday] (@date datetime)
RETURNS int AS  
BEGIN 
	declare @day datetime
	set @date = dateadd(day, -1, @date)
	return (year(@date) * 10000 + month(@date) * 100 + day(@date))
END


GO
/****** Object:  UserDefinedFunction [dbo].[int_date_week]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--返回日期所在周的第一天的日期
CREATE  FUNCTION [dbo].[int_date_week] (@Date INT)
RETURNS INT AS
BEGIN 
	DECLARE	@DateTime DATETIME
	
	SET @DateTime = CAST(@Date AS VARCHAR(8))
	
	SET @DateTime = DATEADD(DAY, DATEPART(weekday, @DateTime)*(-1) + 1, @DateTime)
	
	SET @Date = YEAR(@DateTime) *10000 + MONTH(@DateTime)*100 + DAY(@DateTime)
	
	RETURN @Date
	
END

                                         


GO
/****** Object:  UserDefinedFunction [dbo].[int_week_series]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--print dbo.int_week_series(200501310000, 200502090000)

--format: yyyymmddhhmm
CREATE FUNCTION [dbo].[int_week_series](@base_date bigint, @calc_date bigint)
RETURNS int AS
BEGIN
	return dbo.week_series(cast((@base_date / 10000) as varchar(8)), cast((@calc_date / 10000) as varchar(8)))
	
END

GO
/****** Object:  UserDefinedFunction [dbo].[intdate_to_str]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--print dbo.intdate_to_str(199802031623)
--print dbo.intdate_to_str(19980203)

CREATE FUNCTION [dbo].[intdate_to_str](@Date bigint)
RETURNS varchar(19) AS  
BEGIN 
	return dbo.strdate_to_str(@Date)
END
GO
/****** Object:  UserDefinedFunction [dbo].[ms_to_hour]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[ms_to_hour](@ms int)
RETURNS float AS  
BEGIN 
	return round(cast(@ms as numeric(38, 6)) / (1000/*秒*/ * 60/*分*/ * 60/*小时*/), 2)
END

GO
/****** Object:  UserDefinedFunction [dbo].[ms_to_int_sec]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--print dbo.ms_to_int_sec(1500)

CREATE FUNCTION [dbo].[ms_to_int_sec](@ms int)
RETURNS int AS  
BEGIN 
	return (@ms + 500) / 1000
END



GO
/****** Object:  UserDefinedFunction [dbo].[sec_to_hour]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--print dbo.sec_to_hour(7200 + 60 * 15)

CREATE FUNCTION [dbo].[sec_to_hour](@sec int)
RETURNS float AS  
BEGIN 
	return round(cast(@sec as numeric(38, 6)) / (60/*分*/ * 60/*小时*/), 2)
END


GO
/****** Object:  UserDefinedFunction [dbo].[sec_to_time]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select [dbo].[sec_to_time](5441816)
CREATE FUNCTION [dbo].[sec_to_time] (@time int )
RETURNS varchar(20) AS  
BEGIN 
	declare  @hour  int, @min int, @sec int, @retval varchar (20)
	
	select @sec = @time % 60, 	@time = @time / 60
	select @min = @time % 60, 	@time = @time / 60
	select @hour = @time, 	@retval = ''

	if @hour < 10 	set @retval = @retval + '0'
	set @retval = @retval + ltrim(str(@hour)) + ':'
	if @min < 10  	set @retval = @retval + '0'
	set @retval = @retval + ltrim(str(@min)) + ':'
	if @sec < 10  	set @retval = @retval + '0'
	set @retval = @retval + ltrim(str(@sec)) 

	return @retval

END
GO
/****** Object:  UserDefinedFunction [dbo].[strdate_to_str]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--select dbo.strdate_to_str(19980203162359)
CREATE FUNCTION [dbo].[strdate_to_str](@strDate varchar(14))
RETURNS varchar(19) AS  
BEGIN 
	declare @datelen int
--	declare @strDate varchar(12)
	declare @result varchar(19)

--	set @strDate = @Date
	set @datelen = len(@strDate)
	set @result = ''

	if @datelen >= 14 begin --yyyymmddhhmmss
		set @result = ':' + substring(@strDate, 13, 2)
	end
	
	if @datelen >= 12 begin	--yyyymmddhhmm
		set @result = ':' + substring(@strDate, 11, 2) + @result
		goto L_ADD_HOUR
	end
	if @datelen >= 10 begin	--yyyymmddhh
		set @result = ':00'
L_ADD_HOUR:
		set @result = substring(@strDate, 9, 2) + @result
		goto L_ADD_YEAR
	end
	else if @datelen >= 8 begin --yyyymmdd
L_ADD_YEAR:
		set @result = substring(@strDate, 7, 2) + ' ' + @result	
		goto L_ADD_MONTH
	end
	else if @datelen >= 6 begin	--yyyymm
L_ADD_MONTH:
		set @result = substring(@strDate, 5, 2) + '-' + @result
	end	
	set @result = left(@strDate, 4) + '-' + @result
	
	return case when @datelen > 6 then
					@result
				else 
					left(@result, len(@result) - 1) 
		   end

END


GO
/****** Object:  UserDefinedFunction [dbo].[time_to_bigint]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  FUNCTION [dbo].[time_to_bigint] (@time datetime, @unit int)
RETURNS bigint AS
BEGIN 

	declare @result bigint, @idate bigint, @itime bigint

	select  	@idate = year(@time) * 10000 + month(@time) * 100 + day(@time), 
		@itime = datepart(hour, @time) * 100 + datepart(minute, @time) / @unit * @unit

	select @result = 10000 * @idate + @itime
	return @result
END

GO
/****** Object:  UserDefinedFunction [dbo].[week_series]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--print dbo.week_series('20050131', '20050207')
CREATE FUNCTION [dbo].[week_series](@base_date datetime, @calc_date datetime)
RETURNS int AS  
BEGIN 
	return cast((@calc_date - @base_date) as int) / 7
END


GO
/****** Object:  UserDefinedFunction [dbo].[week_series_to_str]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--print dbo.week_series_to_str('20050201', 0)
--print dbo.week_series_to_str('20050201', dbo.week_series('20050201', '20050209'))

CREATE FUNCTION [dbo].[week_series_to_str](@base_date datetime, @week_series int)
RETURNS varchar(18) AS  
BEGIN
	declare @begin_date datetime
	set @begin_date = @base_date + @week_series * 7
	return convert(varchar(8), @begin_date, 112) + '～' + convert(varchar(8), @begin_date + 6, 112)
END


GO
/****** Object:  Table [dbo].[Action]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Action](
	[ActId] [char](30) NOT NULL,
	[ActName] [varchar](50) NOT NULL,
	[ActTitle] [varchar](100) NOT NULL,
	[ModId] [varchar](200) NOT NULL,
	[SortId] [int] NULL,
	[CtrlLoc] [tinyint] NULL,
	[AllReady] [int] NULL,
	[PartReady] [int] NULL,
	[NotReady] [int] NULL,
	[Reverse] [bit] NULL,
	[FlagLoc] [tinyint] NOT NULL,
	[FieldX] [text] NULL,
	[ActType] [tinyint] NULL,
	[Fields] [varchar](100) NULL,
	[MultiRec] [bit] NULL,
	[ActSQL] [text] NULL,
	[ActSP] [text] NULL,
	[OnAct] [text] NULL,
	[OnTrue] [text] NULL,
	[OnFalse] [text] NULL,
	[Popup] [bit] NULL,
	[ActTab] [varchar](50) NULL,
	[ActPage] [varchar](50) NULL,
	[ActKey] [varchar](50) NULL,
	[Params] [varchar](200) NULL,
	[Width] [smallint] NULL,
	[Height] [smallint] NULL,
	[ExistSet] [bit] NULL,
	[SetFlag] [int] NULL,
	[ResetFlag] [int] NULL,
	[Visible] [bit] NULL,
	[Global] [bit] NULL,
	[IconFile] [varchar](50) NULL,
	[IconCls] [varchar](50) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Action] PRIMARY KEY CLUSTERED 
(
	[ActId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BaseInfo]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BaseInfo](
	[BaseInfo] [int] NOT NULL,
	[CanEdit] [bit] NULL,
 CONSTRAINT [PK_BaseInfo] PRIMARY KEY CLUSTERED 
(
	[BaseInfo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Calendar]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Calendar](
	[CalDate] [int] NOT NULL,
	[CalYear] [smallint] NULL,
	[CalMonth] [tinyint] NULL,
	[CalDay] [tinyint] NULL,
	[WeekDay] [tinyint] NULL,
	[Weeks] [tinyint] NULL,
	[Days] [smallint] NULL,
	[Yesterday] [int] NULL,
	[Tomorrow] [int] NULL,
	[LunarDate] [int] NULL,
	[MWeeks] [tinyint] NULL,
 CONSTRAINT [PK_Calendar] PRIMARY KEY CLUSTERED 
(
	[CalDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CalendarSolarData]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CalendarSolarData](
	[xYear] [int] NOT NULL,
	[data] [char](7) NOT NULL,
	[dataInt] [int] NOT NULL,
 CONSTRAINT [PK_aCD_CalendarSolarData] PRIMARY KEY CLUSTERED 
(
	[xYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CallBack]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CallBack](
	[CallBackId] [int] IDENTITY(1,1) NOT NULL,
	[ObjName] [varchar](50) NOT NULL,
	[EventName] [varchar](50) NOT NULL,
	[Sequence] [int] NOT NULL,
	[SqlText] [nvarchar](4000) NOT NULL,
	[OnSuccess] [varchar](20) NOT NULL,
	[OnFailure] [varchar](20) NOT NULL,
	[Description] [varchar](200) NULL,
	[xtype] [int] NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_CallBack] PRIMARY KEY CLUSTERED 
(
	[CallBackId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Chart]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Chart](
	[DataWin] [char](30) NOT NULL,
	[ChartId] [smallint] NOT NULL,
	[Title] [varchar](200) NULL,
	[Chart] [varchar](20) NOT NULL,
	[Params] [varchar](100) NULL,
	[AxisX] [varchar](20) NULL,
	[AxisY] [varchar](200) NULL,
	[UnitX] [varchar](20) NULL,
	[UnitY] [varchar](50) NULL,
	[Chart1] [varchar](20) NULL,
	[AxisY1] [varchar](100) NULL,
	[UnitY1] [varchar](20) NULL,
	[Chart2] [varchar](20) NULL,
	[AxisY2] [varchar](100) NULL,
	[UnitY2] [varchar](20) NULL,
	[Crossed] [bit] NULL,
	[Scripts] [text] NULL,
	[Filter] [varchar](500) NULL,
	[Show3D] [bit] NULL,
	[AddLink] [bit] NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Chart] PRIMARY KEY CLUSTERED 
(
	[DataWin] ASC,
	[ChartId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[City]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[City](
	[State] [int] NOT NULL,
	[City] [int] NOT NULL,
	[CityName] [varchar](50) NOT NULL,
	[Country] [int] NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_City] PRIMARY KEY CLUSTERED 
(
	[State] ASC,
	[City] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Country]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Country](
	[Country] [int] NOT NULL,
	[CountryName] [varchar](50) NULL,
	[ShortName] [varchar](20) NULL,
	[Name_Chn] [varchar](50) NULL,
	[Name_Eng] [varchar](50) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Country] PRIMARY KEY CLUSTERED 
(
	[Country] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DataWin]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DataWin](
	[DataWin] [char](30) NOT NULL,
	[dwTitle] [varchar](100) NULL,
	[dwType] [tinyint] NULL,
	[KeyField] [varchar](30) NULL,
	[KeySort] [varchar](50) NULL,
	[GrpField] [varchar](30) NULL,
	[StatFields] [varchar](2000) NULL,
	[dwSQL] [text] NULL,
	[Rows] [smallint] NULL,
	[Cols] [smallint] NULL,
	[Fields] [text] NULL,
	[FieldX] [text] NULL,
	[Params] [text] NULL,
	[Chart] [varchar](20) NULL,
	[AxisX] [varchar](20) NULL,
	[AxisY] [varchar](100) NULL,
	[UnitX] [varchar](50) NULL,
	[UnitY] [varchar](50) NULL,
	[Chart1] [varchar](20) NULL,
	[AxisY1] [varchar](100) NULL,
	[UnitY1] [varchar](50) NULL,
	[Chart2] [varchar](20) NULL,
	[AxisY2] [varchar](100) NULL,
	[UnitY2] [varchar](50) NULL,
	[RowKey] [varchar](50) NULL,
	[ColKey] [varchar](50) NULL,
	[StatKey] [varchar](50) NULL,
	[ViewPage] [varchar](50) NULL,
	[EditMod] [varchar](30) NULL,
	[EditTable] [varchar](50) NULL,
	[EditFields] [varchar](200) NULL,
	[EditSQL] [text] NULL,
	[KeyPerson] [varchar](50) NULL,
	[KeyGroup] [varchar](50) NULL,
	[KeyDept] [varchar](50) NULL,
	[Scripts] [text] NULL,
	[Locks] [tinyint] NULL,
	[ExTpl] [varchar](50) NULL,
	[Show3D] [bit] NULL,
	[AddLink] [bit] NULL,
	[LinkAge] [char](30) NULL,
	[LinkPage] [varchar](100) NULL,
	[LinkURL] [varchar](200) NULL,
	[Inspect] [varchar](max) NULL,
	[Filter] [varchar](max) NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_DataWin] PRIMARY KEY CLUSTERED 
(
	[DataWin] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DbLink]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DbLink](
	[DbLink] [varchar](20) NOT NULL,
	[Host] [varchar](20) NULL,
	[LogUser] [varchar](20) NULL,
	[LogPass] [varchar](100) NULL,
	[DbType] [tinyint] NULL,
	[SplitKey] [varchar](50) NULL,
	[SplitValue] [varchar](100) NULL,
	[Summary] [varchar](500) NULL,
	[ActFlag] [int] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_DbLink] PRIMARY KEY CLUSTERED 
(
	[DbLink] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Define]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Define](
	[KeyID] [smallint] NOT NULL,
	[KeyName] [varchar](30) NOT NULL,
	[Aliases] [varchar](100) NULL,
	[SortField] [varchar](20) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Define] PRIMARY KEY CLUSTERED 
(
	[KeyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DefItem]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DefItem](
	[KeyID] [smallint] NOT NULL,
	[KeyField] [varchar](30) NOT NULL,
	[KeyValue] [varchar](200) NOT NULL,
	[KeySort] [varchar](200) NULL,
	[KeyOrder] [smallint] NULL,
 CONSTRAINT [PK_DefItem] PRIMARY KEY CLUSTERED 
(
	[KeyID] ASC,
	[KeyField] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Dictionary]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Dictionary](
	[DicName] [char](20) NOT NULL,
	[KeyTable] [varchar](50) NOT NULL,
	[SortField] [varchar](50) NULL,
	[KeyField] [varchar](50) NOT NULL,
	[ValueField] [varchar](50) NOT NULL,
	[OrderField] [varchar](50) NOT NULL,
	[Filters] [varchar](200) NULL,
	[Aliases] [varchar](100) NULL,
	[SqlText] [text] NULL,
	[PrivFlag] [tinyint] NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NOT NULL,
	[Filter] [varchar](max) NULL,
 CONSTRAINT [PK_Dictionary] PRIMARY KEY CLUSTERED 
(
	[DicName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[District]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[District](
	[City] [int] NOT NULL,
	[District] [varchar](20) NOT NULL,
	[ShowSeq] [smallint] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_district] PRIMARY KEY CLUSTERED 
(
	[City] ASC,
	[District] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Emails]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Emails](
	[EmailId] [char](30) NOT NULL,
	[Title] [varchar](500) NOT NULL,
	[MailFrom] [varchar](100) NULL,
	[MailTo] [varchar](100) NULL,
	[MailCC] [varchar](100) NULL,
	[MailPage] [varchar](200) NULL,
	[Files] [varchar](200) NULL,
	[Params] [varchar](200) NULL,
	[MassSend] [bit] NULL,
	[SortKey] [varchar](50) NULL,
	[MailSQL] [text] NULL,
	[Summary] [text] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Emails] PRIMARY KEY CLUSTERED 
(
	[EmailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Extend]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Extend](
	[ExtId] [smallint] NOT NULL,
	[ExtKey] [varchar](20) NOT NULL,
	[ExtTable] [varchar](50) NULL,
	[ExtClass] [varchar](100) NULL,
	[ExtAct] [varchar](max) NULL,
	[KeySort] [varchar](50) NULL,
	[KeyTitle] [varchar](50) NULL,
	[KeyPage] [varchar](50) NULL,
	[KeyURL] [varchar](200) NULL,
	[KeyFilter] [varchar](200) NULL,
	[Params] [varchar](200) NULL,
	[ExtSQL] [varchar](max) NULL,
	[CtrlLoc] [tinyint] NOT NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Expand] PRIMARY KEY CLUSTERED 
(
	[ExtId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ExtFields]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ExtFields](
	[ExtId] [smallint] NOT NULL,
	[ExtTable] [varchar](50) NULL,
	[ExtField] [varchar](50) NULL,
	[ExtTitle] [varchar](100) NULL,
	[Format] [varchar](500) NULL,
	[Summary] [varchar](500) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_ExtFields] PRIMARY KEY CLUSTERED 
(
	[ExtId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ExtUsers]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ExtUsers](
	[ExtId] [smallint] NOT NULL,
	[ExtTable] [varchar](50) NULL,
	[ExtPrefix] [varchar](20) NULL,
	[ExtName] [varchar](20) NULL,
	[ExtPass] [varchar](20) NULL,
	[ExtRole] [varchar](20) NULL,
	[ExtTitle] [varchar](100) NULL,
	[ExtInfo] [varchar](200) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_ExtUsers] PRIMARY KEY CLUSTERED 
(
	[ExtId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Favorite]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Favorite](
	[UserId] [char](20) NOT NULL,
	[FavorId] [int] NOT NULL,
	[Title] [varchar](100) NULL,
	[URL] [varchar](500) NULL,
	[AddTime] [datetime] NULL,
	[VisitTime] [datetime] NULL,
	[SortId] [int] NULL,
	[ModId] [varchar](50) NULL,
	[Method] [varchar](50) NULL,
	[FlowID] [int] NULL,
	[NodeId] [int] NULL,
	[Action] [varchar](50) NULL,
	[Params] [text] NULL,
	[Note] [text] NULL,
	[Enabled] [bit] NULL,
	[actflag] [int] NULL,
 CONSTRAINT [PK_Favorite] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC,
	[FavorId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Fields]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Fields](
	[TabName] [char](20) NOT NULL,
	[Field] [char](20) NOT NULL,
	[FieldIndex] [tinyint] NULL,
	[FieldType] [char](20) NULL,
	[FieldLen] [tinyint] NULL,
	[PrimaryKey] [bit] NULL,
	[DispStr] [varchar](100) NULL,
	[Format] [varchar](500) NULL,
	[Summary] [varchar](500) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Fields] PRIMARY KEY CLUSTERED 
(
	[TabName] ASC,
	[Field] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FieldValues]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FieldValues](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[FieldName] [varchar](30) NOT NULL,
	[Description] [varchar](100) NULL,
 CONSTRAINT [PK_FieldVaues] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FieldValuesItem]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FieldValuesItem](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[FieldValuesId] [int] NOT NULL,
	[FieldValue] [int] NOT NULL,
	[Meaning] [varchar](100) NOT NULL,
 CONSTRAINT [PK_FieldValuesItem] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Flow]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Flow](
	[FlowId] [int] NOT NULL,
	[FlowName] [varchar](50) NULL,
	[FlowTitle] [varchar](100) NULL,
	[SortId] [int] NULL,
	[CtrlLoc] [int] NULL,
	[FlowTab] [varchar](20) NULL,
	[FlowKey] [varchar](100) NULL,
	[Fields] [text] NULL,
	[FieldX] [text] NULL,
	[FlowFlag] [int] NULL,
	[Root] [int] NULL,
	[FlowIcon] [varchar](50) NULL,
	[FlowPage] [varchar](50) NULL,
	[InitParams] [varchar](100) NULL,
	[InitSQL] [varchar](200) NULL,
	[InitPage] [varchar](50) NULL,
	[FlowSel] [varchar](50) NULL,
	[Nodes] [smallint] NULL,
	[Summary] [text] NULL,
	[Filter] [varchar](max) NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NULL,
	[FlowType] [tinyint] NOT NULL,
	[Visible] [bit] NOT NULL,
 CONSTRAINT [PK_Flow] PRIMARY KEY CLUSTERED 
(
	[FlowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[His_Action]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[His_Action](
	[LogId] [bigint] NOT NULL,
	[LogLabel] [varchar](50) NULL,
	[LogTime] [smalldatetime] NULL,
	[LogHandler] [varchar](20) NULL,
	[ActId] [char](30) NOT NULL,
	[ActName] [varchar](50) NOT NULL,
	[ActTitle] [varchar](100) NOT NULL,
	[ModId] [varchar](200) NOT NULL,
	[SortId] [int] NULL,
	[CtrlLoc] [tinyint] NULL,
	[AllReady] [int] NULL,
	[PartReady] [int] NULL,
	[NotReady] [int] NULL,
	[Reverse] [bit] NULL,
	[FlagLoc] [tinyint] NOT NULL,
	[FieldX] [text] NULL,
	[ActType] [tinyint] NULL,
	[Fields] [varchar](100) NULL,
	[MultiRec] [bit] NULL,
	[ActSQL] [text] NULL,
	[ActSP] [text] NULL,
	[OnAct] [text] NULL,
	[OnTrue] [text] NULL,
	[OnFalse] [text] NULL,
	[Popup] [bit] NULL,
	[ActTab] [varchar](50) NULL,
	[ActPage] [varchar](50) NULL,
	[ActKey] [varchar](50) NULL,
	[Params] [varchar](200) NULL,
	[Width] [smallint] NULL,
	[Height] [smallint] NULL,
	[ExistSet] [bit] NULL,
	[SetFlag] [int] NULL,
	[ResetFlag] [int] NULL,
	[Visible] [bit] NULL,
	[Global] [bit] NULL,
	[IconFile] [varchar](50) NULL,
	[IconCls] [varchar](50) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_His_Action] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[His_Chart]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[His_Chart](
	[LogId] [bigint] NOT NULL,
	[LogLabel] [varchar](50) NULL,
	[LogTime] [smalldatetime] NULL,
	[LogHandler] [varchar](20) NULL,
	[DataWin] [char](30) NOT NULL,
	[ChartId] [tinyint] NOT NULL,
	[Title] [varchar](200) NULL,
	[Chart] [varchar](20) NOT NULL,
	[Params] [varchar](100) NULL,
	[AxisX] [varchar](20) NULL,
	[AxisY] [varchar](200) NULL,
	[UnitX] [varchar](20) NULL,
	[UnitY] [varchar](20) NULL,
	[Chart1] [varchar](20) NULL,
	[AxisY1] [varchar](100) NULL,
	[UnitY1] [varchar](20) NULL,
	[Chart2] [varchar](20) NULL,
	[AxisY2] [varchar](100) NULL,
	[UnitY2] [varchar](20) NULL,
	[Crossed] [bit] NULL,
	[Scripts] [text] NULL,
	[Filter] [varchar](500) NULL,
	[Show3D] [bit] NULL,
	[AddLink] [bit] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_His_Chart] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[His_DataWin]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[His_DataWin](
	[LogId] [bigint] NOT NULL,
	[LogLabel] [varchar](50) NULL,
	[LogTime] [smalldatetime] NULL,
	[LogHandler] [varchar](20) NULL,
	[DataWin] [char](30) NOT NULL,
	[dwTitle] [varchar](100) NULL,
	[dwType] [tinyint] NULL,
	[KeyField] [varchar](30) NULL,
	[KeySort] [varchar](50) NULL,
	[GrpField] [varchar](30) NULL,
	[StatFields] [varchar](2000) NULL,
	[dwSQL] [text] NULL,
	[Rows] [smallint] NULL,
	[Cols] [smallint] NULL,
	[Fields] [text] NULL,
	[FieldX] [text] NULL,
	[Params] [text] NULL,
	[Chart] [varchar](20) NULL,
	[AxisX] [varchar](20) NULL,
	[AxisY] [varchar](100) NULL,
	[UnitX] [varchar](50) NULL,
	[UnitY] [varchar](50) NULL,
	[Chart1] [varchar](50) NULL,
	[AxisY1] [varchar](100) NULL,
	[UnitY1] [varchar](50) NULL,
	[Chart2] [varchar](20) NULL,
	[AxisY2] [varchar](100) NULL,
	[UnitY2] [varchar](50) NULL,
	[RowKey] [varchar](50) NULL,
	[ColKey] [varchar](50) NULL,
	[StatKey] [varchar](50) NULL,
	[ViewPage] [varchar](50) NULL,
	[EditMod] [varchar](30) NULL,
	[EditTable] [varchar](50) NULL,
	[EditFields] [varchar](200) NULL,
	[EditSQL] [text] NULL,
	[KeyPerson] [varchar](50) NULL,
	[KeyGroup] [varchar](50) NULL,
	[KeyDept] [varchar](50) NULL,
	[Scripts] [text] NULL,
	[Locks] [tinyint] NULL,
	[ExTpl] [varchar](50) NULL,
	[Show3D] [bit] NULL,
	[AddLink] [bit] NULL,
	[LinkAge] [char](30) NULL,
	[LinkPage] [varchar](100) NULL,
	[LinkURL] [varchar](200) NULL,
	[Inspect] [varchar](max) NULL,
	[Filter] [varchar](max) NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_His_DataWin] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[His_Define]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[His_Define](
	[LogId] [bigint] NOT NULL,
	[LogLabel] [varchar](50) NULL,
	[LogTime] [smalldatetime] NULL,
	[LogHandler] [varchar](20) NULL,
	[KeyID] [smallint] NOT NULL,
	[KeyName] [varchar](30) NOT NULL,
	[Aliases] [varchar](100) NULL,
	[SortField] [varchar](20) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_His_Define] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[His_DefItem]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[His_DefItem](
	[LogId] [bigint] NOT NULL,
	[LogLabel] [varchar](50) NULL,
	[LogTime] [smalldatetime] NULL,
	[LogHandler] [varchar](20) NULL,
	[KeyID] [smallint] NOT NULL,
	[KeyName] [varchar](30) NULL,
	[KeyField] [varchar](30) NOT NULL,
	[KeyValue] [varchar](200) NOT NULL,
	[KeySort] [varchar](200) NULL,
	[KeyOrder] [smallint] NULL,
 CONSTRAINT [PK_His_DefItem] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[His_Dictionary]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[His_Dictionary](
	[LogId] [bigint] NOT NULL,
	[LogLabel] [varchar](50) NULL,
	[LogTime] [smalldatetime] NULL,
	[LogHandler] [varchar](20) NULL,
	[DicName] [char](20) NOT NULL,
	[KeyTable] [varchar](50) NOT NULL,
	[SortField] [varchar](50) NULL,
	[KeyField] [varchar](50) NOT NULL,
	[ValueField] [varchar](50) NOT NULL,
	[OrderField] [varchar](50) NOT NULL,
	[Filters] [varchar](200) NULL,
	[Aliases] [varchar](100) NULL,
	[SqlText] [text] NULL,
	[PrivFlag] [tinyint] NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NOT NULL,
	[Filter] [varchar](max) NULL,
 CONSTRAINT [PK_His_Dictionary] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[His_Emails]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[His_Emails](
	[LogId] [bigint] NOT NULL,
	[LogLabel] [varchar](50) NULL,
	[LogTime] [smalldatetime] NULL,
	[LogHandler] [varchar](20) NULL,
	[EmailId] [char](30) NOT NULL,
	[Title] [varchar](500) NOT NULL,
	[MailFrom] [varchar](100) NULL,
	[MailTo] [varchar](100) NULL,
	[MailCC] [varchar](100) NULL,
	[MailPage] [varchar](200) NULL,
	[Files] [varchar](200) NULL,
	[Params] [varchar](200) NULL,
	[MassSend] [bit] NULL,
	[SortKey] [varchar](50) NULL,
	[MailSQL] [text] NULL,
	[Summary] [text] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_His_Emails] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[His_ExtUsers]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[His_ExtUsers](
	[LogId] [bigint] NOT NULL,
	[LogLabel] [varchar](50) NULL,
	[LogTime] [smalldatetime] NULL,
	[LogHandler] [varchar](20) NULL,
	[ExtId] [smallint] NOT NULL,
	[ExtTable] [varchar](50) NULL,
	[ExtPrefix] [varchar](20) NULL,
	[ExtName] [varchar](20) NULL,
	[ExtPass] [varchar](20) NULL,
	[ExtRole] [varchar](20) NULL,
	[ExtTitle] [varchar](100) NULL,
	[ExtInfo] [varchar](200) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_His_ExtUsers] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[His_Fields]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[His_Fields](
	[LogId] [bigint] NOT NULL,
	[LogLabel] [varchar](50) NULL,
	[LogTime] [smalldatetime] NULL,
	[LogHandler] [varchar](20) NULL,
	[TabName] [char](20) NOT NULL,
	[Field] [char](20) NOT NULL,
	[FieldIndex] [tinyint] NULL,
	[FieldType] [char](20) NULL,
	[FieldLen] [tinyint] NULL,
	[PrimaryKey] [bit] NULL,
	[DispStr] [varchar](100) NULL,
	[Format] [varchar](500) NULL,
	[Summary] [varchar](500) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_His_Fields] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[His_Flow]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[His_Flow](
	[LogId] [bigint] NOT NULL,
	[LogLabel] [varchar](50) NULL,
	[LogTime] [smalldatetime] NULL,
	[LogHandler] [varchar](20) NULL,
	[FlowId] [int] NOT NULL,
	[FlowName] [varchar](50) NULL,
	[FlowTitle] [varchar](100) NULL,
	[SortId] [int] NULL,
	[CtrlLoc] [int] NULL,
	[FlowTab] [varchar](20) NULL,
	[FlowKey] [varchar](100) NULL,
	[Fields] [text] NULL,
	[FieldX] [text] NULL,
	[FlowFlag] [int] NULL,
	[Root] [int] NULL,
	[FlowIcon] [varchar](50) NULL,
	[FlowPage] [varchar](50) NULL,
	[InitParams] [varchar](100) NULL,
	[InitSQL] [varchar](200) NULL,
	[InitPage] [varchar](50) NULL,
	[FlowSel] [varchar](50) NULL,
	[Nodes] [smallint] NULL,
	[Summary] [text] NULL,
	[Filter] [varchar](max) NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NULL,
	[FlowType] [tinyint] NULL,
	[Visible] [bit] NULL,
 CONSTRAINT [PK_His_Flow] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[His_Links]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[His_Links](
	[LogId] [bigint] NOT NULL,
	[LogLabel] [varchar](50) NULL,
	[LogTime] [smalldatetime] NULL,
	[LogHandler] [varchar](20) NULL,
	[LinkId] [int] NOT NULL,
	[SortId] [int] NOT NULL,
	[Topic] [varchar](100) NOT NULL,
	[LinkTime] [datetime] NOT NULL,
	[ValidTime] [datetime] NULL,
	[LinkFile] [varchar](50) NULL,
	[WWW] [varchar](250) NULL,
	[Summary] [text] NULL,
	[Acked] [bit] NULL,
	[IconFile] [varchar](50) NULL,
	[IconCls] [varchar](50) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_His_Links] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[His_Modules]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[His_Modules](
	[LogId] [bigint] NOT NULL,
	[LogLabel] [varchar](50) NULL,
	[LogTime] [smalldatetime] NULL,
	[LogHandler] [varchar](20) NULL,
	[ModId] [char](30) NOT NULL,
	[ModName] [char](100) NOT NULL,
	[ModIndex] [int] NULL,
	[ParentId] [char](30) NULL,
	[SortId] [int] NULL,
	[CtrlLoc] [tinyint] NOT NULL,
	[VisitPriv] [tinyint] NULL,
	[TabPriv] [tinyint] NULL,
	[SubPriv] [tinyint] NULL,
	[BtnMark] [int] NULL,
	[TabName] [char](50) NOT NULL,
	[TabKey] [char](30) NOT NULL,
	[IntTabKey] [bit] NULL,
	[AutoTabKey] [bit] NULL,
	[Pickup] [bit] NULL,
	[SubTabName] [char](50) NULL,
	[SubTabKey] [char](30) NULL,
	[IntSubKey] [bit] NULL,
	[AutoSubKey] [bit] NULL,
	[DataWin] [varchar](50) NULL,
	[ModPage] [varchar](50) NULL,
	[InitPage] [varchar](50) NULL,
	[MaxRows] [int] NULL,
	[SchType] [tinyint] NULL,
	[SchPage] [varchar](50) NULL,
	[CalPage] [varchar](50) NULL,
	[ComboPage] [varchar](50) NULL,
	[EditPage] [varchar](50) NULL,
	[ViewPage] [varchar](50) NULL,
	[BatAddPage] [varchar](50) NULL,
	[BatDelPage] [varchar](50) NULL,
	[ViewSP] [varchar](200) NULL,
	[InputPage] [varchar](50) NULL,
	[SubSchPage] [varchar](50) NULL,
	[SubEditPage] [varchar](50) NULL,
	[SubViewPage] [varchar](50) NULL,
	[SubViewSP] [varchar](200) NULL,
	[InitSP] [varchar](200) NULL,
	[AckSP] [varchar](200) NULL,
	[UnackSP] [varchar](200) NULL,
	[SchSP] [text] NULL,
	[SubSchSP] [varchar](200) NULL,
	[SubListSP] [varchar](200) NULL,
	[SubInsertSP] [varchar](200) NULL,
	[OnEnter] [varchar](100) NULL,
	[OnLeave] [varchar](100) NULL,
	[OnInsert] [varchar](300) NULL,
	[OnUpdate] [varchar](300) NULL,
	[OnDelete] [varchar](300) NULL,
	[OnSubInsert] [varchar](300) NULL,
	[OnSubUpdate] [varchar](300) NULL,
	[OnSubDelete] [varchar](300) NULL,
	[Chart] [varchar](20) NULL,
	[AxisX] [varchar](20) NULL,
	[AxisY] [varchar](100) NULL,
	[UnitX] [varchar](50) NULL,
	[UnitY] [varchar](50) NULL,
	[Chart1] [varchar](20) NULL,
	[AxisY1] [varchar](100) NULL,
	[UnitY1] [varchar](50) NULL,
	[Chart2] [varchar](20) NULL,
	[AxisY2] [varchar](100) NULL,
	[UnitY2] [varchar](50) NULL,
	[PrintMark] [tinyint] NULL,
	[Summary] [text] NULL,
	[Flow] [text] NULL,
	[Filter] [varchar](max) NULL,
	[SortKeys] [text] NULL,
	[Fields] [text] NULL,
	[FieldX] [text] NULL,
	[StatFields] [text] NULL,
	[SchFields] [text] NULL,
	[SubSchFields] [text] NULL,
	[SubListFields] [text] NULL,
	[Relation] [text] NULL,
	[Formats] [text] NULL,
	[PickLinks] [text] NULL,
	[InitSQL] [text] NULL,
	[NewKeySQL] [text] NULL,
	[SchItems] [text] NULL,
	[SchSQL] [text] NULL,
	[ViewSQL] [text] NULL,
	[EditSQL] [text] NULL,
	[InsertSQL] [text] NULL,
	[UpdateSQL] [text] NULL,
	[DeleteSQL] [text] NULL,
	[SubSchItems] [text] NULL,
	[NewSubKeySQL] [text] NULL,
	[SubSchSQL] [text] NULL,
	[SubListSQL] [text] NULL,
	[SubEditSQL] [text] NULL,
	[SubViewSQL] [text] NULL,
	[SubInsertSQL] [text] NULL,
	[SubUpdateSQL] [text] NULL,
	[SubDeleteSQL] [text] NULL,
	[Template] [text] NULL,
	[Prompts] [text] NULL,
	[Visible] [bit] NULL,
	[KeyPerson] [varchar](50) NULL,
	[KeyGroup] [varchar](50) NULL,
	[KeyDept] [varchar](50) NULL,
	[KeyDefault] [varchar](max) NULL,
	[SchLocks] [tinyint] NULL,
	[SubLocks] [tinyint] NULL,
	[LstLocks] [tinyint] NULL,
	[SchExTpl] [varchar](50) NULL,
	[ExTpl] [varchar](50) NULL,
	[SubExTpl] [varchar](50) NULL,
	[Show3D] [bit] NULL,
	[AddLink] [bit] NULL,
	[Acked] [bit] NULL,
	[IconFile] [varchar](50) NULL,
	[IconCls] [varchar](50) NULL,
	[Enabled] [bit] NULL,
	[Inspect] [varchar](max) NULL,
	[PrivFilter] [varchar](max) NULL,
	[InitFields] [varchar](max) NULL,
	[popup] [bit] NULL,
	[width] [int] NULL,
	[height] [int] NULL,
 CONSTRAINT [PK_his_modules] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[His_Node]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[His_Node](
	[LogId] [bigint] NOT NULL,
	[LogLabel] [varchar](50) NULL,
	[LogTime] [smalldatetime] NULL,
	[LogHandler] [varchar](20) NULL,
	[FlowName] [varchar](50) NULL,
	[FlowId] [int] NOT NULL,
	[NodeId] [int] NOT NULL,
	[NodeType] [smallint] NULL,
	[SupNode] [smallint] NULL,
	[NodeName] [varchar](100) NULL,
	[NodeIcon] [varchar](50) NULL,
	[ModId] [varchar](30) NULL,
	[Oper] [varchar](20) NULL,
	[ActId] [varchar](30) NULL,
	[LinkFile] [varchar](50) NULL,
	[LinkTpl] [varchar](50) NULL,
	[LinkURL] [varchar](50) NULL,
	[DataWin] [varchar](50) NULL,
	[ExecSql] [text] NULL,
	[NodeLoc] [tinyint] NOT NULL,
	[AllReady] [int] NULL,
	[PartReady] [int] NULL,
	[NotReady] [int] NULL,
	[SetFlag] [int] NULL,
	[ResetFlag] [int] NULL,
	[Loads] [text] NULL,
	[Saves] [text] NULL,
	[Drops] [text] NULL,
	[Options] [text] NULL,
	[Popup] [bit] NULL,
	[Width] [smallint] NULL,
	[Height] [smallint] NULL,
	[CtrlLoc] [int] NULL,
	[Enabled] [bit] NULL,
	[SubFlowId] [int] NULL,
 CONSTRAINT [PK_His_Node] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[His_Sort]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[His_Sort](
	[LogId] [bigint] NOT NULL,
	[LogLabel] [varchar](50) NULL,
	[LogTime] [smalldatetime] NULL,
	[LogHandler] [varchar](20) NULL,
	[SortId] [int] NOT NULL,
	[Sort] [varchar](200) NOT NULL,
	[Sort01] [smallint] NOT NULL,
	[Sort02] [smallint] NOT NULL,
	[Sort03] [smallint] NOT NULL,
	[Sort04] [smallint] NOT NULL,
	[Sort05] [smallint] NOT NULL,
	[Sort06] [smallint] NOT NULL,
	[IconFile] [varchar](50) NULL,
	[RootUrl] [varchar](50) NULL,
	[HtmlFile] [varchar](50) NULL,
	[IconCls] [varchar](50) NULL,
	[Summary] [varchar](500) NULL,
	[remote] [varchar](50) NULL,
	[Leaf] [bit] NULL,
	[CtrlLoc] [int] NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_His_Sort] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Holidays]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Holidays](
	[Nation] [int] NOT NULL,
	[HolId] [int] NOT NULL,
	[HolType] [tinyint] NULL,
	[WeekDay] [tinyint] NULL,
	[WeekNo] [tinyint] NULL,
	[Invert] [bit] NULL,
	[Days] [tinyint] NULL,
	[Yearly] [smallint] NULL,
	[RecDate] [int] NULL,
	[Holiday] [varchar](50) NULL,
	[CalDate] [int] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Holidays] PRIMARY KEY CLUSTERED 
(
	[Nation] ASC,
	[HolId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[HotFields]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[HotFields](
	[HotKey] [char](20) NOT NULL,
	[HotModule] [varchar](50) NULL,
	[HotURL] [varchar](100) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_HotFields] PRIMARY KEY CLUSTERED 
(
	[HotKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Links]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Links](
	[LinkId] [int] NOT NULL,
	[SortId] [int] NOT NULL,
	[Topic] [varchar](100) NOT NULL,
	[LinkTime] [datetime] NOT NULL,
	[ValidTime] [datetime] NULL,
	[LinkFile] [varchar](50) NULL,
	[WWW] [varchar](250) NULL,
	[Summary] [text] NULL,
	[Acked] [bit] NULL,
	[IconFile] [varchar](50) NULL,
	[IconCls] [varchar](50) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Links] PRIMARY KEY CLUSTERED 
(
	[LinkId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Message]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Message](
	[MsgId] [smallint] NOT NULL,
	[MsgName] [varchar](500) NOT NULL,
	[MsgType] [smallint] NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Message] PRIMARY KEY CLUSTERED 
(
	[MsgId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Modules]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Modules](
	[ModId] [char](30) NOT NULL,
	[ModName] [char](100) NOT NULL,
	[ModIndex] [int] NULL,
	[ParentId] [char](30) NULL,
	[SortId] [int] NULL,
	[CtrlLoc] [tinyint] NOT NULL,
	[VisitPriv] [tinyint] NULL,
	[TabPriv] [tinyint] NULL,
	[SubPriv] [tinyint] NULL,
	[BtnMark] [int] NULL,
	[TabName] [char](50) NOT NULL,
	[TabKey] [char](30) NOT NULL,
	[IntTabKey] [bit] NULL,
	[AutoTabKey] [bit] NULL,
	[Pickup] [bit] NULL,
	[SubTabName] [char](50) NULL,
	[SubTabKey] [char](30) NULL,
	[IntSubKey] [bit] NULL,
	[AutoSubKey] [bit] NULL,
	[DataWin] [varchar](50) NULL,
	[ModPage] [varchar](50) NULL,
	[InitPage] [varchar](50) NULL,
	[MaxRows] [int] NULL,
	[SchType] [tinyint] NULL,
	[SchPage] [varchar](50) NULL,
	[CalPage] [varchar](50) NULL,
	[ComboPage] [varchar](50) NULL,
	[EditPage] [varchar](50) NULL,
	[ViewPage] [varchar](50) NULL,
	[BatAddPage] [varchar](50) NULL,
	[BatDelPage] [varchar](50) NULL,
	[ViewSP] [varchar](200) NULL,
	[InputPage] [varchar](50) NULL,
	[SubSchPage] [varchar](50) NULL,
	[SubEditPage] [varchar](50) NULL,
	[SubViewPage] [varchar](50) NULL,
	[SubViewSP] [varchar](200) NULL,
	[InitSP] [varchar](200) NULL,
	[AckSP] [varchar](200) NULL,
	[UnackSP] [varchar](200) NULL,
	[SchSP] [text] NULL,
	[SubSchSP] [varchar](200) NULL,
	[SubListSP] [varchar](200) NULL,
	[SubInsertSP] [varchar](200) NULL,
	[OnEnter] [varchar](100) NULL,
	[OnLeave] [varchar](100) NULL,
	[OnInsert] [varchar](300) NULL,
	[OnUpdate] [varchar](300) NULL,
	[OnDelete] [varchar](300) NULL,
	[OnSubInsert] [varchar](300) NULL,
	[OnSubUpdate] [varchar](300) NULL,
	[OnSubDelete] [varchar](300) NULL,
	[Chart] [varchar](20) NULL,
	[AxisX] [varchar](20) NULL,
	[AxisY] [varchar](100) NULL,
	[UnitX] [varchar](50) NULL,
	[UnitY] [varchar](50) NULL,
	[Chart1] [varchar](20) NULL,
	[AxisY1] [varchar](100) NULL,
	[UnitY1] [varchar](50) NULL,
	[Chart2] [varchar](20) NULL,
	[AxisY2] [varchar](100) NULL,
	[UnitY2] [varchar](50) NULL,
	[PrintMark] [tinyint] NULL,
	[Summary] [text] NULL,
	[Flow] [text] NULL,
	[Filter] [varchar](max) NULL,
	[SortKeys] [text] NULL,
	[Fields] [text] NULL,
	[FieldX] [text] NULL,
	[StatFields] [text] NULL,
	[SchFields] [text] NULL,
	[SubSchFields] [text] NULL,
	[SubListFields] [text] NULL,
	[Relation] [text] NULL,
	[Formats] [text] NULL,
	[PickLinks] [text] NULL,
	[InitSQL] [text] NULL,
	[NewKeySQL] [text] NULL,
	[SchItems] [text] NULL,
	[SchSQL] [text] NULL,
	[ViewSQL] [text] NULL,
	[EditSQL] [text] NULL,
	[InsertSQL] [text] NULL,
	[UpdateSQL] [text] NULL,
	[DeleteSQL] [text] NULL,
	[SubSchItems] [text] NULL,
	[NewSubKeySQL] [text] NULL,
	[SubSchSQL] [text] NULL,
	[SubListSQL] [text] NULL,
	[SubEditSQL] [text] NULL,
	[SubViewSQL] [text] NULL,
	[SubInsertSQL] [text] NULL,
	[SubUpdateSQL] [text] NULL,
	[SubDeleteSQL] [text] NULL,
	[Template] [text] NULL,
	[Prompts] [text] NULL,
	[Visible] [bit] NULL,
	[KeyPerson] [varchar](50) NULL,
	[KeyGroup] [varchar](50) NULL,
	[KeyDept] [varchar](50) NULL,
	[KeyDefault] [varchar](max) NULL,
	[SchLocks] [tinyint] NULL,
	[SubLocks] [tinyint] NULL,
	[LstLocks] [tinyint] NULL,
	[SchExTpl] [varchar](50) NULL,
	[ExTpl] [varchar](50) NULL,
	[SubExTpl] [varchar](50) NULL,
	[Show3D] [bit] NULL,
	[AddLink] [bit] NULL,
	[Acked] [bit] NULL,
	[IconFile] [varchar](50) NULL,
	[IconCls] [varchar](50) NULL,
	[Enabled] [bit] NULL,
	[Inspect] [varchar](max) NULL,
	[PrivFilter] [varchar](max) NULL,
	[InitFields] [varchar](max) NULL,
	[popup] [bit] NULL,
	[width] [int] NULL,
	[height] [int] NULL,
 CONSTRAINT [PK_Modules] PRIMARY KEY NONCLUSTERED 
(
	[ModId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Monthly]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Monthly](
	[caldate] [int] NOT NULL,
 CONSTRAINT [PK_Monthly] PRIMARY KEY CLUSTERED 
(
	[caldate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Nation]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Nation](
	[Nation] [int] NOT NULL,
	[NationName] [varchar](100) NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_DomainAbbr] PRIMARY KEY CLUSTERED 
(
	[Nation] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Node]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Node](
	[FlowId] [int] NOT NULL,
	[NodeId] [int] NOT NULL,
	[NodeType] [smallint] NULL,
	[SupNode] [smallint] NULL,
	[NodeName] [varchar](100) NULL,
	[NodeIcon] [varchar](50) NULL,
	[ModId] [varchar](30) NULL,
	[Oper] [varchar](20) NULL,
	[ActId] [varchar](30) NULL,
	[LinkFile] [varchar](50) NULL,
	[LinkTpl] [varchar](50) NULL,
	[LinkURL] [varchar](50) NULL,
	[DataWin] [varchar](50) NULL,
	[ExecSql] [text] NULL,
	[NodeLoc] [tinyint] NOT NULL,
	[AllReady] [int] NULL,
	[PartReady] [int] NULL,
	[NotReady] [int] NULL,
	[SetFlag] [int] NULL,
	[ResetFlag] [int] NULL,
	[Loads] [text] NULL,
	[Saves] [text] NULL,
	[Drops] [text] NULL,
	[Options] [text] NULL,
	[Popup] [bit] NULL,
	[Width] [smallint] NULL,
	[Height] [smallint] NULL,
	[CtrlLoc] [int] NULL,
	[Enabled] [bit] NULL,
	[SubFlowId] [int] NULL,
 CONSTRAINT [PK_Node] PRIMARY KEY CLUSTERED 
(
	[FlowId] ASC,
	[NodeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Pickup]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Pickup](
	[PickId] [int] NOT NULL,
	[UserId] [char](20) NOT NULL,
	[ModuleId] [char](20) NOT NULL,
	[PriKey] [char](20) NOT NULL,
	[SecKey] [char](20) NULL,
	[OtherKeys] [text] NULL,
	[Fields] [text] NULL,
	[PickDate] [int] NULL,
 CONSTRAINT [PK_Pickup] PRIMARY KEY CLUSTERED 
(
	[PickId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PrivFilter]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PrivFilter](
	[Role] [smallint] NOT NULL,
	[FiltKey] [varchar](50) NOT NULL,
	[Title] [varchar](200) NULL,
	[FiltSet] [varchar](max) NULL,
	[FiltDict] [varchar](50) NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_PrivFilter1] PRIMARY KEY CLUSTERED 
(
	[Role] ASC,
	[FiltKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PrivFilter_NEW]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PrivFilter_NEW](
	[FiltID] [int] NOT NULL,
	[FiltKey] [varchar](50) NOT NULL,
	[Title] [varchar](200) NULL,
	[FiltSet] [varchar](max) NULL,
	[FiltDict] [varchar](50) NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_PrivFilter] PRIMARY KEY CLUSTERED 
(
	[FiltID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PrivLoc]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PrivLoc](
	[PrivLoc] [tinyint] NOT NULL,
	[PrivName] [nvarchar](200) NULL,
	[PrivSort] [tinyint] NULL,
	[SubIdx] [tinyint] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_PrivLoc] PRIMARY KEY CLUSTERED 
(
	[PrivLoc] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PrivSort]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PrivSort](
	[PrivSort] [tinyint] NOT NULL,
	[PrivSortName] [nvarchar](200) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_PrivSort_1] PRIMARY KEY CLUSTERED 
(
	[PrivSort] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Query]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Query](
	[QueryId] [int] NOT NULL,
	[UserId] [varchar](20) NOT NULL,
	[title] [varchar](100) NOT NULL,
	[ModId] [varchar](30) NOT NULL,
	[Method] [tinyint] NOT NULL,
	[SaveTime] [datetime] NULL,
	[LoadTime] [datetime] NULL,
	[SchKey01] [varchar](50) NULL,
	[SchExp01] [varchar](50) NULL,
	[SchItem01] [varchar](50) NULL,
	[SchLogic01] [varchar](50) NULL,
	[SchKey02] [varchar](50) NULL,
	[SchExp02] [varchar](50) NULL,
	[SchItem02] [varchar](50) NULL,
	[SchLogic02] [varchar](50) NULL,
	[SchKey03] [varchar](50) NULL,
	[SchExp03] [varchar](50) NULL,
	[SchItem03] [varchar](50) NULL,
	[SchLogic03] [varchar](50) NULL,
	[SchKey04] [varchar](50) NULL,
	[SchExp04] [varchar](50) NULL,
	[SchItem04] [varchar](50) NULL,
	[SchLogic04] [varchar](50) NULL,
	[SchKey05] [varchar](50) NULL,
	[SchExp05] [varchar](50) NULL,
	[SchItem05] [varchar](50) NULL,
	[SchLogic05] [varchar](50) NULL,
	[SchKey06] [varchar](50) NULL,
	[SchExp06] [varchar](50) NULL,
	[SchItem06] [varchar](50) NULL,
	[SchDtFrom] [varchar](20) NULL,
	[SchDtTo] [varchar](20) NULL,
	[SchNumFrom] [varchar](20) NULL,
	[SchNumTo] [varchar](20) NULL,
	[SortKeys] [varchar](200) NULL,
 CONSTRAINT [PK_Query] PRIMARY KEY CLUSTERED 
(
	[QueryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Roles]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Roles](
	[Role] [smallint] NOT NULL,
	[RoleName] [varchar](50) NOT NULL,
	[Privilege] [varchar](100) NOT NULL,
	[Summary] [text] NULL,
	[RootSort] [int] NULL,
	[RootFile] [varchar](100) NULL,
	[RootURL] [varchar](100) NULL,
	[RecPriv] [varchar](100) NULL,
	[ExtInfo] [varchar](200) NULL,
	[RecPerson] [text] NULL,
	[RecGroup] [text] NULL,
	[RecDept] [text] NULL,
	[RoleType] [tinyint] NULL,
	[MacMatch] [bit] NULL,
	[HideSorts] [varchar](500) NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Roles1] PRIMARY KEY CLUSTERED 
(
	[Role] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Roles_NEW]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Roles_NEW](
	[Role] [smallint] NOT NULL,
	[RoleName] [varchar](50) NOT NULL,
	[Privilege] [varchar](100) NOT NULL,
	[Summary] [text] NULL,
	[RootSort] [int] NULL,
	[RootFile] [varchar](100) NULL,
	[RootURL] [varchar](100) NULL,
	[RecPriv] [varchar](100) NULL,
	[ExtInfo] [varchar](200) NULL,
	[RecPerson] [text] NULL,
	[RecGroup] [text] NULL,
	[RecDept] [text] NULL,
	[RoleType] [tinyint] NULL,
	[MacMatch] [bit] NULL,
	[HideSorts] [varchar](500) NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NULL,
	[Filts] [varchar](100) NULL,
 CONSTRAINT [PK_Roles] PRIMARY KEY CLUSTERED 
(
	[Role] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Service]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Service](
	[Service] [char](20) NOT NULL,
	[Host] [varchar](32) NOT NULL,
	[Port] [smallint] NOT NULL,
	[SvcType] [tinyint] NOT NULL,
	[Context] [varchar](50) NULL,
	[ClsName] [varchar](50) NULL,
	[Description] [varchar](200) NULL,
	[ActFlag] [int] NULL,
	[Enabled] [bit] NULL,
	[ModIndex] [smallint] NULL,
 CONSTRAINT [PK_Service] PRIMARY KEY CLUSTERED 
(
	[Service] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SheetID]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SheetID](
	[SheetType] [tinyint] NOT NULL,
	[TableName] [varchar](50) NOT NULL,
	[SheetId] [int] NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_SheetID] PRIMARY KEY CLUSTERED 
(
	[SheetType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Sort]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Sort](
	[SortId] [int] NOT NULL,
	[Sort] [varchar](200) NOT NULL,
	[Sort01] [smallint] NOT NULL,
	[Sort02] [smallint] NOT NULL,
	[Sort03] [smallint] NOT NULL,
	[Sort04] [smallint] NOT NULL,
	[Sort05] [smallint] NOT NULL,
	[Sort06] [smallint] NOT NULL,
	[IconFile] [varchar](50) NULL,
	[RootUrl] [varchar](50) NULL,
	[HtmlFile] [varchar](50) NULL,
	[IconCls] [varchar](50) NULL,
	[Summary] [varchar](500) NULL,
	[remote] [varchar](50) NULL,
	[Leaf] [bit] NOT NULL,
	[CtrlLoc] [int] NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Sort] PRIMARY KEY NONCLUSTERED 
(
	[SortId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_Sort] UNIQUE CLUSTERED 
(
	[Sort] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_Sort01] UNIQUE NONCLUSTERED 
(
	[Sort01] ASC,
	[Sort02] ASC,
	[Sort03] ASC,
	[Sort04] ASC,
	[Sort05] ASC,
	[Sort06] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[State]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[State](
	[State] [int] NOT NULL,
	[StateName] [varchar](50) NOT NULL,
	[Country] [int] NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_State] PRIMARY KEY CLUSTERED 
(
	[State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_State] UNIQUE NONCLUSTERED 
(
	[StateName] ASC,
	[Country] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Strings]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Strings](
	[Segment] [char](20) NOT NULL,
	[Item] [varchar](50) NOT NULL,
	[Chinese] [varchar](200) NULL,
	[English] [varchar](200) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Tables]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Tables](
	[TabName] [char](20) NOT NULL,
	[Summary] [varchar](100) NOT NULL,
 CONSTRAINT [PK_Tables] PRIMARY KEY CLUSTERED 
(
	[TabName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Tags]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Tags](
	[TagName] [char](20) NOT NULL,
	[TagDesc] [varchar](50) NOT NULL,
	[TagParams] [varchar](200) NULL,
 CONSTRAINT [PK_Tags] PRIMARY KEY CLUSTERED 
(
	[TagName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TempItems]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TempItems](
	[RepId] [int] NOT NULL,
	[ItemId] [tinyint] NOT NULL,
	[Item] [varchar](20) NULL,
	[A] [varchar](20) NULL,
	[B] [varchar](20) NULL,
	[C] [varchar](20) NULL,
	[D] [varchar](20) NULL,
	[E] [varchar](20) NULL,
	[F] [varchar](20) NULL,
	[G] [varchar](20) NULL,
	[H] [varchar](20) NULL,
	[I] [varchar](20) NULL,
	[J] [varchar](20) NULL,
	[K] [varchar](20) NULL,
	[L] [varchar](20) NULL,
	[M] [varchar](20) NULL,
	[N] [varchar](20) NULL,
	[O] [varchar](20) NULL,
	[P] [varchar](20) NULL,
	[Q] [varchar](20) NULL,
	[R] [varchar](20) NULL,
	[S] [varchar](20) NULL,
	[T] [varchar](20) NULL,
	[CanEdit] [bit] NULL,
 CONSTRAINT [PK_TempItems] PRIMARY KEY CLUSTERED 
(
	[RepId] ASC,
	[ItemId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Template]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Template](
	[TempId] [int] NOT NULL,
	[Title] [varchar](100) NOT NULL,
	[SortId] [int] NOT NULL,
	[RowNo] [tinyint] NOT NULL,
	[ColNo] [tinyint] NOT NULL,
	[RowHead] [bit] NULL,
	[A] [varchar](20) NULL,
	[B] [varchar](20) NULL,
	[C] [varchar](20) NULL,
	[D] [varchar](20) NULL,
	[E] [varchar](20) NULL,
	[F] [varchar](20) NULL,
	[G] [varchar](20) NULL,
	[H] [varchar](20) NULL,
	[I] [varchar](20) NULL,
	[J] [varchar](20) NULL,
	[K] [varchar](20) NULL,
	[L] [varchar](20) NULL,
	[M] [varchar](20) NULL,
	[N] [varchar](20) NULL,
	[O] [varchar](20) NULL,
	[P] [varchar](20) NULL,
	[Q] [varchar](20) NULL,
	[R] [varchar](20) NULL,
	[S] [varchar](20) NULL,
	[T] [varchar](20) NULL,
	[ColHead] [bit] NULL,
	[C01] [varchar](20) NULL,
	[C02] [varchar](20) NULL,
	[C03] [varchar](20) NULL,
	[C04] [varchar](20) NULL,
	[C05] [varchar](20) NULL,
	[C06] [varchar](20) NULL,
	[C07] [varchar](20) NULL,
	[C08] [varchar](20) NULL,
	[C09] [varchar](20) NULL,
	[C10] [varchar](20) NULL,
	[C11] [varchar](20) NULL,
	[C12] [varchar](20) NULL,
	[C13] [varchar](20) NULL,
	[C14] [varchar](20) NULL,
	[C15] [varchar](20) NULL,
	[C16] [varchar](20) NULL,
	[C17] [varchar](20) NULL,
	[C18] [varchar](20) NULL,
	[C19] [varchar](20) NULL,
	[C20] [varchar](20) NULL,
	[C21] [varchar](20) NULL,
	[C22] [varchar](20) NULL,
	[C23] [varchar](20) NULL,
	[C24] [varchar](20) NULL,
	[C25] [varchar](20) NULL,
	[C26] [varchar](20) NULL,
	[C27] [varchar](20) NULL,
	[C28] [varchar](20) NULL,
	[C29] [varchar](20) NULL,
	[C30] [varchar](20) NULL,
	[C31] [varchar](20) NULL,
	[C32] [varchar](20) NULL,
	[C33] [varchar](20) NULL,
	[C34] [varchar](20) NULL,
	[C35] [varchar](20) NULL,
	[C36] [varchar](20) NULL,
	[C37] [varchar](20) NULL,
	[C38] [varchar](20) NULL,
	[C39] [varchar](20) NULL,
	[C40] [varchar](20) NULL,
	[C41] [varchar](20) NULL,
	[C42] [varchar](20) NULL,
	[C43] [varchar](20) NULL,
	[C44] [varchar](20) NULL,
	[C45] [varchar](20) NULL,
	[C46] [varchar](20) NULL,
	[C47] [varchar](20) NULL,
	[C48] [varchar](20) NULL,
	[C49] [varchar](20) NULL,
	[C50] [varchar](20) NULL,
	[MakDept] [varchar](50) NULL,
	[Label] [varchar](50) NULL,
	[RowFormular] [text] NULL,
	[ColFormular] [text] NULL,
	[RowTitles] [text] NULL,
	[ColTitles] [text] NULL,
	[Note] [text] NULL,
	[Maker] [varchar](20) NULL,
	[Acker] [varchar](20) NULL,
	[CanEdit] [bit] NULL,
 CONSTRAINT [PK_Template] PRIMARY KEY CLUSTERED 
(
	[TempId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TempRep]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TempRep](
	[RepId] [int] NOT NULL,
	[TempId] [int] NOT NULL,
	[Title] [varchar](100) NOT NULL,
	[SortId] [int] NOT NULL,
	[RepDate] [datetime] NULL,
	[RowNo] [tinyint] NOT NULL,
	[ColNo] [tinyint] NOT NULL,
	[A] [varchar](20) NULL,
	[B] [varchar](20) NULL,
	[C] [varchar](20) NULL,
	[D] [varchar](20) NULL,
	[E] [varchar](20) NULL,
	[F] [varchar](20) NULL,
	[G] [varchar](20) NULL,
	[H] [varchar](20) NULL,
	[I] [varchar](20) NULL,
	[J] [varchar](20) NULL,
	[K] [varchar](20) NULL,
	[L] [varchar](20) NULL,
	[M] [varchar](20) NULL,
	[N] [varchar](20) NULL,
	[O] [varchar](20) NULL,
	[P] [varchar](20) NULL,
	[Q] [varchar](20) NULL,
	[R] [varchar](20) NULL,
	[S] [varchar](20) NULL,
	[T] [varchar](20) NULL,
	[Label] [varchar](50) NULL,
	[MakDept] [varchar](50) NULL,
	[RowFormular] [varchar](200) NULL,
	[ColFormular] [varchar](200) NULL,
	[RowTitles] [varchar](200) NULL,
	[ColTitles] [varchar](200) NULL,
	[Note] [varchar](200) NULL,
	[Maker] [varchar](20) NULL,
	[Acker] [varchar](20) NULL,
	[CanEdit] [bit] NULL,
 CONSTRAINT [PK_TempRep] PRIMARY KEY CLUSTERED 
(
	[RepId] ASC,
	[TempId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TplFileLib]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TplFileLib](
	[TplId] [varchar](30) NOT NULL,
	[TplTitle] [varchar](200) NULL,
	[TplFile] [varchar](200) NULL,
	[Inputs] [varchar](200) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_TplFileLib] PRIMARY KEY CLUSTERED 
(
	[TplId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Trace]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Trace](
	[OperId] [bigint] NOT NULL,
	[Operator] [varchar](20) NOT NULL,
	[OperTime] [datetime] NOT NULL,
	[Operation] [varchar](4000) NOT NULL,
 CONSTRAINT [PK_Trace] PRIMARY KEY CLUSTERED 
(
	[OperId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TreeDef]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TreeDef](
	[TreeId] [int] NOT NULL,
	[TreeName] [varchar](50) NOT NULL,
	[Title] [varchar](50) NULL,
	[Summary] [varchar](200) NULL,
	[Degree] [tinyint] NULL,
	[Field01] [varchar](50) NULL,
	[Field02] [varchar](50) NULL,
	[Field03] [varchar](50) NULL,
	[Field04] [varchar](50) NULL,
	[Field05] [varchar](50) NULL,
	[TreeURL] [varchar](200) NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_TreeDef] PRIMARY KEY CLUSTERED 
(
	[TreeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TreeItem]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TreeItem](
	[TreeId] [int] NOT NULL,
	[ItemId] [int] NOT NULL,
	[Item01] [varchar](50) NULL,
	[Item02] [varchar](50) NULL,
	[Item03] [varchar](50) NULL,
	[Item04] [varchar](50) NULL,
	[Item05] [varchar](50) NULL,
	[ItemURL] [varchar](200) NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_TreeItem] PRIMARY KEY CLUSTERED 
(
	[TreeId] ASC,
	[ItemId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Users]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Users](
	[UserId] [char](30) NOT NULL,
	[UserName] [varchar](30) NOT NULL,
	[Password] [varchar](120) NULL,
	[Role] [smallint] NOT NULL,
	[DeptId] [smallint] NULL,
	[Style] [varchar](50) NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NULL,
	[LastDate] [int] NULL,
	[Validate] [int] NULL,
	[ErrTimes] [tinyint] NULL,
	[MaxTimes] [tinyint] NULL,
	[Locked] [bit] NULL,
	[Mac] [varchar](18) NULL,
	[eMail] [varchar](200) NULL,
	[actflag] [int] NULL,
	[LastPassword] [varchar](200) NULL,
 CONSTRAINT [PK_Users1] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Users_NEW]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Users_NEW](
	[UserId] [char](30) NOT NULL,
	[UserName] [varchar](30) NOT NULL,
	[Password] [varchar](120) NULL,
	[Role] [smallint] NOT NULL,
	[DeptId] [smallint] NULL,
	[Style] [varchar](50) NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NULL,
	[LastDate] [int] NULL,
	[Validate] [int] NULL,
	[ErrTimes] [smallint] NULL,
	[MaxTimes] [tinyint] NULL,
	[Locked] [bit] NULL,
	[Mac] [varchar](18) NULL,
	[eMail] [varchar](200) NULL,
	[actflag] [int] NULL,
	[Filts] [varchar](100) NULL,
 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UserStyle]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UserStyle](
	[UserId] [char](20) NOT NULL,
	[ObjType] [smallint] NOT NULL,
	[ObjId] [varchar](50) NOT NULL,
	[Style01] [text] NULL,
	[Style02] [text] NULL,
	[Style03] [text] NULL,
	[Style04] [text] NULL,
	[Style05] [text] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_UserStyle] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC,
	[ObjType] ASC,
	[ObjId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Version]    Script Date: 2016/12/8 13:07:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Version](
	[version] [char](20) NOT NULL,
	[verdate] [int] NOT NULL,
 CONSTRAINT [PK_version] PRIMARY KEY CLUSTERED 
(
	[version] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Action]    Script Date: 2016/12/8 13:07:48 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Action] ON [dbo].[Action]
(
	[ActName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Action_1]    Script Date: 2016/12/8 13:07:48 ******/
CREATE NONCLUSTERED INDEX [IX_Action_1] ON [dbo].[Action]
(
	[ModId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_CallBack]    Script Date: 2016/12/8 13:07:48 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_CallBack] ON [dbo].[CallBack]
(
	[ObjName] ASC,
	[EventName] ASC,
	[Sequence] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Define_KeyName]    Script Date: 2016/12/8 13:07:48 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Define_KeyName] ON [dbo].[Define]
(
	[KeyName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [UX_Extend_ExtKey]    Script Date: 2016/12/8 13:07:48 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_Extend_ExtKey] ON [dbo].[Extend]
(
	[ExtKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_ExtUsers]    Script Date: 2016/12/8 13:07:48 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_ExtUsers] ON [dbo].[ExtUsers]
(
	[ExtPrefix] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_ExtUsers_1]    Script Date: 2016/12/8 13:07:48 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_ExtUsers_1] ON [dbo].[ExtUsers]
(
	[ExtTable] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Links_Topic]    Script Date: 2016/12/8 13:07:48 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Links_Topic] ON [dbo].[Links]
(
	[Topic] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Message_MsgName]    Script Date: 2016/12/8 13:07:48 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Message_MsgName] ON [dbo].[Message]
(
	[MsgName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Modules]    Script Date: 2016/12/8 13:07:48 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Modules] ON [dbo].[Modules]
(
	[ModName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_PrivLoc]    Script Date: 2016/12/8 13:07:48 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_PrivLoc] ON [dbo].[PrivLoc]
(
	[PrivName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_PrivSort]    Script Date: 2016/12/8 13:07:48 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_PrivSort] ON [dbo].[PrivSort]
(
	[PrivSortName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Roles_RoleName]    Script Date: 2016/12/8 13:07:48 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Roles_RoleName] ON [dbo].[Roles_NEW]
(
	[RoleName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Service]    Script Date: 2016/12/8 13:07:48 ******/
CREATE NONCLUSTERED INDEX [IX_Service] ON [dbo].[Service]
(
	[Host] ASC,
	[Port] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_SheetID]    Script Date: 2016/12/8 13:07:48 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_SheetID] ON [dbo].[SheetID]
(
	[TableName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Action] ADD  CONSTRAINT [DF_Action_Reverse]  DEFAULT ((0)) FOR [Reverse]
GO
ALTER TABLE [dbo].[Action] ADD  CONSTRAINT [DF_Action_Visible]  DEFAULT ((1)) FOR [Visible]
GO
ALTER TABLE [dbo].[CallBack] ADD  CONSTRAINT [DF_CallBack_xtype]  DEFAULT ((0)) FOR [xtype]
GO
ALTER TABLE [dbo].[CallBack] ADD  CONSTRAINT [DF_CallBack_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Chart] ADD  CONSTRAINT [DF_Chart_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[City] ADD  CONSTRAINT [DF_City_CountryId]  DEFAULT ((86)) FOR [Country]
GO
ALTER TABLE [dbo].[City] ADD  CONSTRAINT [DF_City_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Country] ADD  CONSTRAINT [DF_Country_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[DbLink] ADD  CONSTRAINT [DF_DbLinks_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Define] ADD  CONSTRAINT [DF_Define_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Dictionary] ADD  CONSTRAINT [DF_Dictionary_PrivFlag]  DEFAULT ((0)) FOR [PrivFlag]
GO
ALTER TABLE [dbo].[Dictionary] ADD  CONSTRAINT [DF_Dictionary_Acked]  DEFAULT ((0)) FOR [Acked]
GO
ALTER TABLE [dbo].[District] ADD  CONSTRAINT [DF_district_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Extend] ADD  CONSTRAINT [DF_Extend_CtrlLoc]  DEFAULT ((0)) FOR [CtrlLoc]
GO
ALTER TABLE [dbo].[ExtUsers] ADD  CONSTRAINT [DF_ExtUsers_ExtName]  DEFAULT ('RegName') FOR [ExtName]
GO
ALTER TABLE [dbo].[ExtUsers] ADD  CONSTRAINT [DF_ExtUsers_ExtPass]  DEFAULT ('RegPass') FOR [ExtPass]
GO
ALTER TABLE [dbo].[ExtUsers] ADD  CONSTRAINT [DF_ExtUsers_ExtRole]  DEFAULT ('RegRole') FOR [ExtRole]
GO
ALTER TABLE [dbo].[Favorite] ADD  CONSTRAINT [DF_Favorite_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Fields] ADD  CONSTRAINT [DF_Fields_FieldIndex]  DEFAULT ((0)) FOR [FieldIndex]
GO
ALTER TABLE [dbo].[Fields] ADD  CONSTRAINT [DF_Fields_FieldLen]  DEFAULT ((0)) FOR [FieldLen]
GO
ALTER TABLE [dbo].[Fields] ADD  CONSTRAINT [DF_Fields_PrimaryKey]  DEFAULT ((0)) FOR [PrimaryKey]
GO
ALTER TABLE [dbo].[Fields] ADD  CONSTRAINT [DF_Fields_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Flow] ADD  CONSTRAINT [DF_Flow_FlowType]  DEFAULT ((1)) FOR [FlowType]
GO
ALTER TABLE [dbo].[Flow] ADD  CONSTRAINT [DF_Flow_Visible]  DEFAULT ((1)) FOR [Visible]
GO
ALTER TABLE [dbo].[His_Action] ADD  CONSTRAINT [DF_His_Action_LogTime]  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[His_Chart] ADD  CONSTRAINT [DF_His_Chart_LogTime]  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[His_DataWin] ADD  CONSTRAINT [DF_His_DataWin_LogTime]  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[His_Define] ADD  CONSTRAINT [DF_His_Define_LogTime]  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[His_DefItem] ADD  CONSTRAINT [DF_His_DefItem_LogTime]  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[His_Dictionary] ADD  CONSTRAINT [DF_His_Dictionary_LogTime]  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[His_Emails] ADD  CONSTRAINT [DF_His_Emails_LogTime]  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[His_ExtUsers] ADD  CONSTRAINT [DF_His_ExtUsers_LogTime]  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[His_Fields] ADD  CONSTRAINT [DF_His_Fields_LogTime]  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[His_Flow] ADD  CONSTRAINT [DF_His_Flow_LogTime]  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[His_Links] ADD  CONSTRAINT [DF_His_Links_LogTime]  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[His_Modules] ADD  CONSTRAINT [DF_his_modules_LogTime]  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[His_Node] ADD  CONSTRAINT [DF_His_Node_LogTime]  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[Holidays] ADD  CONSTRAINT [DF_Holidays_Days]  DEFAULT ((1)) FOR [Days]
GO
ALTER TABLE [dbo].[HotFields] ADD  CONSTRAINT [DF_HotFields_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Message] ADD  CONSTRAINT [DF_Message_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Modules] ADD  CONSTRAINT [DF_Modules_ModIndex]  DEFAULT ((100)) FOR [ModIndex]
GO
ALTER TABLE [dbo].[Modules] ADD  CONSTRAINT [DF_Modules_TabPriv]  DEFAULT ((15)) FOR [TabPriv]
GO
ALTER TABLE [dbo].[Modules] ADD  CONSTRAINT [DF_Modules_SubPriv]  DEFAULT ((15)) FOR [SubPriv]
GO
ALTER TABLE [dbo].[Modules] ADD  CONSTRAINT [DF_Modules_BtnMark]  DEFAULT (0xFFFFFFFF) FOR [BtnMark]
GO
ALTER TABLE [dbo].[Modules] ADD  CONSTRAINT [DF_Modules_MaxRows]  DEFAULT ((1000)) FOR [MaxRows]
GO
ALTER TABLE [dbo].[Modules] ADD  CONSTRAINT [DF_Modules_Visible]  DEFAULT ((1)) FOR [Visible]
GO
ALTER TABLE [dbo].[Nation] ADD  CONSTRAINT [DF_Nation_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[PrivFilter] ADD  CONSTRAINT [DF_PrivFilter_Enabled1]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[PrivFilter_NEW] ADD  CONSTRAINT [DF_PrivFilter_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[PrivLoc] ADD  CONSTRAINT [DF_PrivLoc_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[PrivSort] ADD  CONSTRAINT [DF_PrivSort_PrivSort]  DEFAULT ((1)) FOR [PrivSort]
GO
ALTER TABLE [dbo].[Service] ADD  CONSTRAINT [DF_Service_UdpPort]  DEFAULT ((0)) FOR [SvcType]
GO
ALTER TABLE [dbo].[Service] ADD  CONSTRAINT [DF_Service_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Service] ADD  CONSTRAINT [DF_Service_ModIndex]  DEFAULT ((-1)) FOR [ModIndex]
GO
ALTER TABLE [dbo].[Sort] ADD  CONSTRAINT [DF_Sort_Sort01]  DEFAULT ((0)) FOR [Sort01]
GO
ALTER TABLE [dbo].[Sort] ADD  CONSTRAINT [DF_Sort_Sort02]  DEFAULT ((0)) FOR [Sort02]
GO
ALTER TABLE [dbo].[Sort] ADD  CONSTRAINT [DF_Sort_Sort03]  DEFAULT ((0)) FOR [Sort03]
GO
ALTER TABLE [dbo].[Sort] ADD  CONSTRAINT [DF_Sort_Sort04]  DEFAULT ((0)) FOR [Sort04]
GO
ALTER TABLE [dbo].[Sort] ADD  CONSTRAINT [DF_Sort_Sort05]  DEFAULT ((0)) FOR [Sort05]
GO
ALTER TABLE [dbo].[Sort] ADD  CONSTRAINT [DF_Sort_Sort06]  DEFAULT ((0)) FOR [Sort06]
GO
ALTER TABLE [dbo].[Sort] ADD  CONSTRAINT [DF_Sort_Leaf]  DEFAULT ((1)) FOR [Leaf]
GO
ALTER TABLE [dbo].[Sort] ADD  CONSTRAINT [DF_Sort_Acked]  DEFAULT ((0)) FOR [Acked]
GO
ALTER TABLE [dbo].[Sort] ADD  CONSTRAINT [DF_Sort_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[State] ADD  CONSTRAINT [DF_State_CountryId]  DEFAULT ((86)) FOR [Country]
GO
ALTER TABLE [dbo].[State] ADD  CONSTRAINT [DF_State_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[TreeDef] ADD  CONSTRAINT [DF_TreeDef_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[TreeItem] ADD  CONSTRAINT [DF_TreeItem_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_Validate1]  DEFAULT ((90)) FOR [Validate]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_MaxErrs1]  DEFAULT ((3)) FOR [MaxTimes]
GO
ALTER TABLE [dbo].[Users_NEW] ADD  CONSTRAINT [DF_Users_Validate]  DEFAULT ((90)) FOR [Validate]
GO
ALTER TABLE [dbo].[Users_NEW] ADD  CONSTRAINT [DF_Users_MaxErrs]  DEFAULT ((3)) FOR [MaxTimes]
GO
ALTER TABLE [dbo].[Chart]  WITH CHECK ADD  CONSTRAINT [FK_Chart_DataWin] FOREIGN KEY([DataWin])
REFERENCES [dbo].[DataWin] ([DataWin])
GO
ALTER TABLE [dbo].[Chart] CHECK CONSTRAINT [FK_Chart_DataWin]
GO
ALTER TABLE [dbo].[DefItem]  WITH CHECK ADD  CONSTRAINT [FK_DefItem_Define] FOREIGN KEY([KeyID])
REFERENCES [dbo].[Define] ([KeyID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DefItem] CHECK CONSTRAINT [FK_DefItem_Define]
GO
ALTER TABLE [dbo].[FieldValuesItem]  WITH CHECK ADD  CONSTRAINT [FK_FieldValuesItem_FieldValueId] FOREIGN KEY([FieldValuesId])
REFERENCES [dbo].[FieldValues] ([ID])
GO
ALTER TABLE [dbo].[FieldValuesItem] CHECK CONSTRAINT [FK_FieldValuesItem_FieldValueId]
GO
ALTER TABLE [dbo].[Flow]  WITH NOCHECK ADD  CONSTRAINT [FK_Flow_Sort] FOREIGN KEY([SortId])
REFERENCES [dbo].[Sort] ([SortId])
GO
ALTER TABLE [dbo].[Flow] CHECK CONSTRAINT [FK_Flow_Sort]
GO
ALTER TABLE [dbo].[Holidays]  WITH CHECK ADD  CONSTRAINT [FK_Holidays_Nation] FOREIGN KEY([Nation])
REFERENCES [dbo].[Nation] ([Nation])
GO
ALTER TABLE [dbo].[Holidays] CHECK CONSTRAINT [FK_Holidays_Nation]
GO
ALTER TABLE [dbo].[Links]  WITH NOCHECK ADD  CONSTRAINT [FK_Links_Sort] FOREIGN KEY([SortId])
REFERENCES [dbo].[Sort] ([SortId])
GO
ALTER TABLE [dbo].[Links] CHECK CONSTRAINT [FK_Links_Sort]
GO
ALTER TABLE [dbo].[Node]  WITH NOCHECK ADD  CONSTRAINT [FK_Node_Flow] FOREIGN KEY([FlowId])
REFERENCES [dbo].[Flow] ([FlowId])
GO
ALTER TABLE [dbo].[Node] CHECK CONSTRAINT [FK_Node_Flow]
GO
ALTER TABLE [dbo].[PrivLoc]  WITH CHECK ADD  CONSTRAINT [FK_PrivLoc_PrivSort] FOREIGN KEY([PrivSort])
REFERENCES [dbo].[PrivSort] ([PrivSort])
GO
ALTER TABLE [dbo].[PrivLoc] CHECK CONSTRAINT [FK_PrivLoc_PrivSort]
GO
ALTER TABLE [dbo].[Roles]  WITH CHECK ADD  CONSTRAINT [FK_Roles_SortId1] FOREIGN KEY([RootSort])
REFERENCES [dbo].[Sort] ([SortId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Roles] CHECK CONSTRAINT [FK_Roles_SortId1]
GO
ALTER TABLE [dbo].[Roles_NEW]  WITH CHECK ADD  CONSTRAINT [FK_Roles_SortId] FOREIGN KEY([RootSort])
REFERENCES [dbo].[Sort] ([SortId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Roles_NEW] CHECK CONSTRAINT [FK_Roles_SortId]
GO
ALTER TABLE [dbo].[TreeItem]  WITH CHECK ADD  CONSTRAINT [FK_TreeItem_TreeId] FOREIGN KEY([TreeId])
REFERENCES [dbo].[TreeDef] ([TreeId])
GO
ALTER TABLE [dbo].[TreeItem] CHECK CONSTRAINT [FK_TreeItem_TreeId]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [FK_Users_Role1] FOREIGN KEY([Role])
REFERENCES [dbo].[Roles] ([Role])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [FK_Users_Role1]
GO
ALTER TABLE [dbo].[Users_NEW]  WITH CHECK ADD  CONSTRAINT [FK_Users_Role] FOREIGN KEY([Role])
REFERENCES [dbo].[Roles_NEW] ([Role])
GO
ALTER TABLE [dbo].[Users_NEW] CHECK CONSTRAINT [FK_Users_Role]
GO
USE [master]
GO
ALTER DATABASE [vxi_def] SET  READ_WRITE 
GO
