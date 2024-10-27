using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Data.Odbc;
using System.Data;
using System.Collections;

namespace MvcGuestbook.Controllers
{

    public class BotController : Controller
    {
        // GET: Bot
        static DataSet query_ds { get; set; }

        public ActionResult Index()
        {
            string Userrole = Request.Cookies["userrole"].Value;
            ViewBag.Username = HttpContext.User.Identity.Name;
            ViewBag.Displaynewbn = false;

            if (Userrole != null)
            {
                if (Userrole == "0")
                {
                    ViewBag.Displaynewbn = true;
                }
            }
            return View();
        }

        public ActionResult Botalarm()
        {
            DataBase_Vib db_bot = new DataBase_Vib(2);
            db_bot.Open();
            DataSet ds = db_bot.ExeQueryToDs("select count(*) c from (select id from hk_botda_alarm_info where is_show=0) T;");
            if (ds != null)
            {
                ViewBag.Vibcount = ds.Tables[0].Rows[0]["c"].ToString();
            }
            ds.Reset();
            ds = db_bot.ExeQueryToDs("SELECT  id, channel_id, device_name, alarm_time,update_time,event_type,alarm_guid, left(max_value,8) max_value,limen_value, " +
                    "case alarm_format when 1 then '定值报警' when 2 then '区域值差' when 3 then '差值报警' when  4 then '故障' when 5 then" +
                    "'故障恢复' else '未知报警' end alarm_type, left(begin_pos,8) begin_pos, left(end_pos,8) end_pos, left(cent_pos,8) cent_pos from hk_botda_alarm_info where is_show=0 order by id desc limit 3;");
            ViewData["ds"] = ds;
            ds.Dispose();

            db_bot.Close();
            db_bot.Dispose();
            return PartialView();

        }

        public ActionResult Setbotdaflag()
        {
            string alarm_id = Request.QueryString["id"];
            string vib_flag = Request.QueryString["flag"];
            DataBase_Vib db_botda = new DataBase_Vib(2);
            db_botda.Open();
            string sql_str = "";
            if (vib_flag == "1")
            {
                sql_str = "update hk_botda_alarm_info set is_show=1 where id=" + alarm_id + ";";
            }
            if (vib_flag == "2")
            {
                sql_str = "update hk_botda_alarm_info set is_show=2 where id=" + alarm_id + ";";
            }

            db_botda.ExeNoQuery(sql_str);



            db_botda.Close();
            db_botda.Dispose();


            return new EmptyResult();
        }


        /// /////////////////////////////////////////////////////


        public ActionResult Botdata()
        {
            string Userrole = Request.Cookies["userrole"].Value;
            ViewBag.Username = HttpContext.User.Identity.Name;
            ViewBag.Displaynewbn = false;

            if (Userrole != null)
            {
                if (Userrole == "0")
                {
                    ViewBag.Displaynewbn = true;
                }
            }
            return View();
        }

        public ActionResult Botdataqy()
        {
            string start_date = Request.QueryString["startdate"];
            string end_date = Request.QueryString["enddate"];
            if (end_date != null)
            {
                end_date = end_date + " 23:59:59";
            }
            string ch_id = Request.QueryString["chid"];
            string idno = Request.QueryString["idno"];

            DataBase_Vib db_bot = new DataBase_Vib(2);
            db_bot.Open();
            if ((start_date == null) && (end_date == null) && (ch_id == null) && (idno == null))
            {
                DataSet ds = db_bot.ExeQueryToDs("select count(*) c from (select id from hk_botda_data) T;");
                if (ds != null)
                {
                    ViewBag.Vibcount = ds.Tables[0].Rows[0]["c"].ToString();
                }
                ds.Reset();
                if (query_ds != null)
                {
                    query_ds.Dispose();
                }
                query_ds = db_bot.ExeQueryToDs("SELECT  id, channel_id, device_name, rece_time,left(dot_len,8) dot_len,left(begin_pos,8) begin_pos, data_size FROM hk_botda_data order by id desc limit 5000;");
                //ds = query_ds;
                ViewData["ds"] = query_ds;
                //ds.Dispose();
            }
            else
            {
                string total_str = "select count(*) c from (select id from hk_botda_data where 1=1 ";
                string sel_str = "SELECT  id, channel_id, device_name,  rece_time, left(dot_len,8) dot_len, left(begin_pos,8) begin_pos, data_size FROM  hk_botda_data where 1=1 ";

                int pa_nu = 0;
                if (start_date != null)
                {
                    if (start_date.Length > 0)
                    {

                        total_str = total_str + " and rece_time>'" + start_date + "' ";
                        sel_str = sel_str + " and rece_time>'" + start_date + "' ";
                        pa_nu = pa_nu + 1;
                    }
                }

                if (end_date != null)
                {
                    if (end_date.Length > 0)
                    {
                        total_str = total_str + " and rece_time<'" + end_date + "' ";
                        sel_str = sel_str + " and rece_time<'" + end_date + "' ";
                        pa_nu = pa_nu + 1;
                    }
                }

                if (ch_id != null)
                {
                    if (ch_id.Length > 0)
                    {

                        total_str = total_str + " and  channel_id=" + ch_id;
                        sel_str = sel_str + " and channel_id=" + ch_id;
                        pa_nu = pa_nu + 1;
                    }
                }

                if (idno != null)
                {
                    if (idno.Length > 0)
                    {

                        total_str = total_str + " and  id=" + idno;
                        sel_str = sel_str + " and  id=" + idno;

                        pa_nu = pa_nu + 1;
                    }
                }


                total_str = total_str + ") T";
                sel_str = sel_str + "  order by id desc limit 5000;";

                DataSet ds = db_bot.ExeQueryToDs(total_str);
                if (ds != null)
                {
                    ViewBag.Vibcount = ds.Tables[0].Rows[0]["c"].ToString();
                }
                ds.Reset();
                if (query_ds != null)
                {
                    query_ds.Dispose();
                }
                //ds = db_vib.ExeQueryToDs("select id,  push_time, first_push_time, last_push_time, channel_id, sensor_id, center_pos, level, sample_id, sample_name, possibility, event_width, max_intensity, topic, case is_show when 0 then '未确认' when 1 then '已确认' else '误报' end show_check from hk_vib_event_detail  order by id desc;");
                query_ds = db_bot.ExeQueryToDs(sel_str);
                //ds = query_ds;
                ViewData["ds"] = query_ds;

            }
            db_bot.Close();
            db_bot.Dispose();
            return PartialView();


        }

        public ActionResult Botdfypage()
        {
            string curpage = Request.QueryString["npage"];
            ViewData["curpage"] = curpage;
            ViewData["ds"] = query_ds;
            return PartialView();
        }

        public ActionResult Botset()
        {
            string alarm_id = Request.QueryString["id"];
            ViewBag.Eid = alarm_id;

            return PartialView();
        }

        public ActionResult Setbotdata()
        {
            string event_id = Request.QueryString["id"];
            string pos = Request.QueryString["pos"];
            string angle = Request.QueryString["ang"];
            string anno = Request.QueryString["ann"];
            if (anno == null) anno = "";
            DataBase_Vib db_bot = new DataBase_Vib(2);
            db_bot.Open();
            string sql_str = "";
            sql_str = "select count(id) c from  hk_botda_anno where eid=" + event_id+" and dot_pos="+pos;
            DataSet ds = db_bot.ExeQueryToDs(sql_str);
            string count = "";
            count = ds.Tables[0].Rows[0]["c"].ToString();
            if (count!="0")
            {
                sql_str = "update hk_botda_anno set angle=" + angle + ", anno="+anno+" where eid=" + event_id + " and dot_pos=  " + pos + ";";
            }
            else
            {
                sql_str = "insert into hk_botda_anno(eid, dot_pos,angle, anno) values (" + event_id + ","+pos+ ", " + angle + "," + anno + ");";

            }
            ds.Reset();
            db_bot.ExeNoQuery(sql_str);
            db_bot.Close();
            db_bot.Dispose();
            return new EmptyResult();
        }

        /// ////////////////////////////////////////////////////////////////////////////////

        public ActionResult Bothis()
        {
            string Userrole = Request.Cookies["userrole"].Value;
            ViewBag.Username = HttpContext.User.Identity.Name;
            ViewBag.Displaynewbn = false;

            if (Userrole != null)
            {
                if (Userrole == "0")
                {
                    ViewBag.Displaynewbn = true;
                }
            }
            return View();
        }

        public ActionResult Bothisquery()
        {
            string start_date = Request.QueryString["startdate"];
            string end_date = Request.QueryString["enddate"];
            if (end_date != null)
            {
                end_date = end_date + " 23:59:59";
            }
            string ch_id = Request.QueryString["chid"];
            string stats = Request.QueryString["stat"];
            string alarmtype = Request.QueryString["alarmtype"];

            DataBase_Vib db_bot = new DataBase_Vib(2);
            db_bot.Open();
            if ((start_date == null) && (end_date == null) && (ch_id == null) && (stats == null) && (alarmtype == null))
            {
                DataSet ds = db_bot.ExeQueryToDs("select count(*) c from (select id from hk_botda_alarm_info) T;");
                if (ds != null)
                {
                    ViewBag.Vibcount = ds.Tables[0].Rows[0]["c"].ToString();
                }
                ds.Reset();
                if (query_ds != null)
                {
                    query_ds.Dispose();
                }
                query_ds = db_bot.ExeQueryToDs("SELECT  id, channel_id, device_name, alarm_time,update_time,event_type,alarm_guid, left(max_value,8) max_value,limen_value, " +
                    "case alarm_format when 1 then '定值报警' when 2 then '区域值差' when 3 then '差值报警' when  4 then '故障' when 5 then" +
                    "'故障恢复' else '未知报警' end alarm_type, left(begin_pos,8) begin_pos, left(end_pos,8) end_pos, left(cent_pos,8) cent_pos, case is_show when 0 then '未确认' when 1 then '已确认' else '误报' end" +
                    " show_check FROM  hk_botda_alarm_info order by id desc limit 5000;");
                //ds = query_ds;
                ViewData["ds"] = query_ds;
                //ds.Dispose();
            }
            else
            {
                string total_str = "select count(*) c from (select id from hk_botda_alarm_info where 1=1 ";
                string sel_str = "SELECT  id, channel_id, device_name, alarm_time,update_time,event_type,alarm_guid, left(max_value,8) max_value,limen_value, " +
                    "case alarm_format when 1 then '定值报警' when 2 then '区域值差' when 3 then '差值报警' when  4 then '故障' when 5 then" +
                    "'故障恢复' else '未知报警' end alarm_type, left(begin_pos,8) begin_pos, left(end_pos,8) end_pos, left(cent_pos,8) cent_pos, case is_show when 0 then '未确认' when 1 then '已确认' else '误报' end" +
                    " show_check FROM  hk_botda_alarm_info where 1=1 ";

                int pa_nu = 0;
                if (start_date != null)
                {
                    if (start_date.Length > 0)
                    {

                            total_str = total_str + " and push_time>'" + start_date + "' ";
                            sel_str = sel_str + " and push_time>'" + start_date + "' ";
                            pa_nu = pa_nu + 1;
                    }
                }

                if (end_date != null)
                {
                    if (end_date.Length > 0)
                    {
                        total_str = total_str + " and push_time<'" + end_date + "' ";
                        sel_str = sel_str + " and push_time<'" + end_date + "' ";
                        pa_nu = pa_nu + 1;
                    }
                }

                if (ch_id != null)
                {
                    if (ch_id.Length > 0)
                    {

                            total_str = total_str + " and  channel_id=" + ch_id;
                            sel_str = sel_str + " and channel_id=" + ch_id;
                            pa_nu = pa_nu + 1;
                    }
                }

                if (alarmtype != null)
                {
                    if (alarmtype.Length > 0)
                    {

                        total_str = total_str + " and  alarm_format=" + alarmtype ;
                        sel_str = sel_str + " and  alarm_format=" + alarmtype;

                        pa_nu = pa_nu + 1;
                    }
                }

                if (stats != null)
                {
                    if (stats.Length > 0)
                    {
                        if (stats != "0")
                        {
 
                             if (stats == "1")
                             {
                                 total_str = total_str + " and  is_show=1 ";
                                 sel_str = sel_str + " and is_show=1 ";
                             }
                             else if (stats == "2")
                             {
                                 total_str = total_str + " and  is_show=0 ";
                                 sel_str = sel_str + " and is_show=0 ";
                             }
                             else if (stats == "3")
                             {
                                 total_str = total_str + " and  is_show=2 ";
                                 sel_str = sel_str + " and is_show=2 ";
                             }
                            
                            pa_nu = pa_nu + 1;
                        }

                    }
                }

                total_str = total_str + ") T";
                sel_str = sel_str + "  order by id desc limit 5000;";

                DataSet ds = db_bot.ExeQueryToDs(total_str);
                if (ds != null)
                {
                    ViewBag.Vibcount = ds.Tables[0].Rows[0]["c"].ToString();
                }
                ds.Reset();
                if (query_ds != null)
                {
                    query_ds.Dispose();
                }
                //ds = db_vib.ExeQueryToDs("select id,  push_time, first_push_time, last_push_time, channel_id, sensor_id, center_pos, level, sample_id, sample_name, possibility, event_width, max_intensity, topic, case is_show when 0 then '未确认' when 1 then '已确认' else '误报' end show_check from hk_vib_event_detail  order by id desc;");
                query_ds = db_bot.ExeQueryToDs(sel_str);
                //ds = query_ds;
                ViewData["ds"] = query_ds;

            }
            db_bot.Close();
            db_bot.Dispose();
            return PartialView();
        }

        public ActionResult Botfypage()
        {
            string curpage = Request.QueryString["npage"];
            ViewData["curpage"] = curpage;
            ViewData["ds"] = query_ds;
            return PartialView();
        }

/// //////////////////////////////////////////////////////////////////////////////

        public JsonResult Getpiejson()
        {
            string ch = Request.QueryString["ch"];
            ArrayList xAxisData = new ArrayList();
            ArrayList yAxisData = new ArrayList();
            DataBase_Vib db_bot = new DataBase_Vib(2);
            db_bot.Open();
            string sql_str = "";
            if (ch == null)
            {
                sql_str = "SELECT case alarm_format when 1 then '定值报警' when 2 then '区域值差' when 3 then '差值报警' when  4 then '故障' when 5 then" +
                   "'故障恢复' else '未知报警' end alarm_format,count(*) total FROM  hk_botda_alarm_info group by alarm_format;";
            }
            else {

                sql_str = "SELECT case alarm_format when 1 then '定值报警' when 2 then '区域值差' when 3 then '差值报警' when  4 then '故障' when 5 then" +
               "'故障恢复' else '未知报警' end alarm_format,count(*) total FROM  hk_botda_alarm_info where channel_id=" + ch;
                sql_str=sql_str+ " group by alarm_format;";
            }
            DataSet ds = db_bot.ExeQueryToDs(sql_str);

            foreach (System.Data.DataRow dr in ds.Tables[0].Rows)
            {
                xAxisData.Add(dr["alarm_format"].ToString());
                yAxisData.Add(dr["total"].ToString());
            }
            var result = new { Format= xAxisData, Num = yAxisData };
            db_bot.Close();
            db_bot.Dispose();
            ds.Reset();
            return Json(result, JsonRequestBehavior.AllowGet);

        }

        public JsonResult Getbarjson()
        {
            string ch = Request.QueryString["ch"];
            string eid = Request.QueryString["id"];
            ArrayList xAxisData = new ArrayList();
            ArrayList yAxisData = new ArrayList();
            DataBase_Vib db_bot = new DataBase_Vib(2);
            db_bot.Open();
            string sql_str = "";
            if (eid == null)
            {
                if (ch == null) { 
                    sql_str = "select id, rece_time, data,  begin_pos, dot_len from hk_botda_data order by id desc limit 1;";
                }
                else
                {
                    sql_str = "select id, rece_time, data,  begin_pos, dot_len from hk_botda_data where channel_id=";
                    sql_str = sql_str + ch;
                    sql_str = sql_str + " order by id desc limit 1;";

                }
            }
            else
            {
                sql_str = "select id, rece_time, data,  begin_pos, dot_len from hk_botda_data where id="+eid+";";
            }

            DataSet ds = null;
            System.Data.DataRow dr = null;
            try
            {
                ds = db_bot.ExeQueryToDs(sql_str);
                dr = ds.Tables[0].Rows[0];
            }
            catch { }

            string r_id="";
            string r_data="";
            string r_rece_time="";
            string r_begin_pos="0";
            string r_dot_len="0";
            if (dr != null)
            {
                r_id = dr["id"].ToString();
                r_data = dr["data"].ToString();
                r_rece_time = dr["rece_time"].ToString();
                r_begin_pos = dr["begin_pos"].ToString();
                r_dot_len = dr["dot_len"].ToString();
            }
            double fiber_pos = Convert.ToDouble(r_begin_pos);
            double fiber_dot_len = Convert.ToDouble(r_dot_len);

            int data_pos;
            string temp;
            int t_id = 0;
            string temp_str;
            double local_value_max = 0;
            int id_max = 0;
            double position_max = 0;
            double temp_value = 0;

            while (r_data.Length > 0)
            {

                data_pos = r_data.IndexOf(",");
                if (data_pos > 0)
                {
                    temp = r_data.Substring(0, data_pos);

                    r_data = r_data.Substring(data_pos + 1);

                }
                else
                {
                    temp = r_data;
                    r_data = "";
                }
                if (temp.IndexOf(".-")<0)
                {
                    try
                    {

                        temp_value = Convert.ToDouble(temp);
                    }
                    catch 
                    {
                        int test = 1;
                    }
                }

                // DataRow d = dt.NewRow();
                t_id = t_id + 1;
                fiber_pos = fiber_pos + fiber_dot_len;

                if (System.Math.Abs(temp_value) > System.Math.Abs(local_value_max))
                {
                    local_value_max = temp_value;
                    id_max = t_id;
                    position_max = fiber_pos;
                }
                if (eid == null)//////////////////////////
                {      ///////////////////////////////
                    if (t_id % 10 == 0)
                    {

                        yAxisData.Add(local_value_max.ToString());

                        if (position_max == 0)
                        {
                            position_max = fiber_pos;
                        }
                        temp_str = Convert.ToString(position_max);
                        if (temp_str.Length > 8)
                        {
                            temp_str = temp_str.Substring(0, 8);
                        }
                        xAxisData.Add(temp_str);
                        local_value_max = 0;
                        position_max = 0;

                    }
                }///////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
                else {
                    yAxisData.Add(temp_value.ToString());
                    temp_str = Convert.ToString(fiber_pos);
                    if (temp_str.Length > 8)
                    {
                        temp_str = temp_str.Substring(0, 8);
                    }
                    xAxisData.Add(temp_str);

                }
//////////////////////////////////////////////////////////////////////////
            }

            if (r_id.Length == 0)
            {
                yAxisData.Add("0");
                xAxisData.Add("0");
            }

            var result = new { Pos= xAxisData, Valu = yAxisData };
            db_bot.Close();
            db_bot.Dispose();
            ds.Reset();
            return Json(result, JsonRequestBehavior.AllowGet);

        }

    }


}