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
    public class DtsController : Controller
    {

        static DataSet query_ds { get; set; }
        // GET: Dts
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

        public ActionResult Areadata()
        {
            string creatime = "";
            string query_string = "";
            DataBase_Vib db_dts = new DataBase_Vib(3);
            db_dts.Open();
            DataSet ds = db_dts.ExeQueryToDs("select create_time from  hk_dts_area_real_data order by id desc limit 1;");
            if (ds != null)
            {
                creatime = ds.Tables[0].Rows[0]["create_time"].ToString();
            }
            ds.Reset();
            if (creatime != null)
            {
                query_string = "select id, channel_id, area_no, tmp_warning, high_temp, ava_temp,low_temp,high_pos, " +
                    " low_pos, create_time from  hk_dts_area_real_data where create_time ='" + creatime + "' order by area_no;";
                ds = db_dts.ExeQueryToDs(query_string);
                ViewData["ds"] = ds;
            }

            return PartialView();
        }

        public ActionResult Areaset()
        {
            string creatime = "";
            string query_string = "";
            DataBase_Vib db_dts = new DataBase_Vib(3);
            db_dts.Open();
            DataSet ds = db_dts.ExeQueryToDs("select create_time from  hk_dts_area_real_data order by id desc limit 1;");
            if (ds != null)
            {
                creatime = ds.Tables[0].Rows[0]["create_time"].ToString();
            }
            ds.Reset();

            string areanum = "";
            if (creatime != null)
            {
                query_string = "select count(*) c from  hk_dts_area_real_data where create_time ='" + creatime + "';";
                ds = db_dts.ExeQueryToDs(query_string);
                areanum = ds.Tables[0].Rows[0]["c"].ToString();               
            }
            ds.Reset();
            if ((areanum != null) && (areanum.Length > 0))
            {
                query_string = "select * from hk_dts_area_def order by id desc limit "+ areanum + ";";
                ds = db_dts.ExeQueryToDs(query_string);
                ViewData["ds"] = ds;
            }

            
            return PartialView();
        }

        public ActionResult Areaalarm()
        {
            DataBase_Vib db_dts = new DataBase_Vib(3);
            db_dts.Open();
            DataSet ds = db_dts.ExeQueryToDs("select count(*) c from (select id from hk_dts_real_alarm_info where is_show=0) T;");
            if (ds != null)
            {
                ViewBag.Dtscount = ds.Tables[0].Rows[0]["c"].ToString();
            }
            ds.Reset();
            ds = db_dts.ExeQueryToDs("select id, alarm_time, channel_id, begin_pos, alarm_type, area_no, '0' as point_len from hk_dts_real_alarm_info where is_show=0 order by id desc limit 5;");
            string temp_chid;
            //string temp_id;
            int temp_id;
            string temp_time;
            double temp_pointlen;
            double temp_begin_pos;
            DataSet ds_temp;
            DataRow temp_dr;
            string temp_qureystr = "";
            foreach (System.Data.DataRow dr in ds.Tables[0].Rows)
            {
                temp_id = Convert.ToInt32(dr["id"].ToString());
                temp_time = dr["alarm_time"].ToString();
                temp_chid = dr["channel_id"].ToString();
                temp_begin_pos = Convert.ToDouble(dr["begin_pos"].ToString());
                temp_qureystr = "select channel_id, create_time, point_len from hk_dts_ch_def where create_time<'" + temp_time + "' and channel_id=" + temp_chid + " order by id desc limit 1";
                ds_temp = db_dts.ExeQueryToDs(temp_qureystr);
                temp_pointlen = Convert.ToDouble(ds_temp.Tables[0].Rows[0]["point_len"].ToString());
                temp_begin_pos = temp_begin_pos * temp_pointlen / 100;
                DataColumn[] keys = new DataColumn[1];
                keys[0] = ds.Tables[0].Columns[0];
                ds.Tables[0].PrimaryKey = keys;
                temp_dr = ds.Tables[0].Rows.Find(temp_id);
                temp_dr.BeginEdit();
                temp_dr["begin_pos"] = temp_begin_pos.ToString();
                temp_dr["point_len"] = temp_pointlen.ToString();
                temp_dr.EndEdit();



            }

            ViewData["ds"] = ds;



            ds.Dispose();


            db_dts.Close();
            db_dts.Dispose();

            return PartialView();
        }

        /// ////////////////////////////////////////////////////////////////////////////////

        public ActionResult Dtshis()
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

        public ActionResult Dtshisquery()
        {
            string start_date = Request.QueryString["startdate"];
            string end_date = Request.QueryString["enddate"];
            if (end_date != null)
            {
                end_date = end_date + " 23:59:59";
            }
            string ch_id = Request.QueryString["chid"];
            string areano = Request.QueryString["areano"];
            
            string stats = Request.QueryString["stat"];
            string alarmtype = Request.QueryString["alarmtype"];

            DataBase_Vib db_dts = new DataBase_Vib(3);
            db_dts.Open();
            if ((start_date == null) && (end_date == null) && (ch_id == null) && (stats == null) && (alarmtype == null)&&(areano==null))
            {
                DataSet ds = db_dts.ExeQueryToDs("select count(*) c from (select id from hk_dts_real_alarm_info) T;");
                if (ds != null)
                {
                    ViewBag.Vibcount = ds.Tables[0].Rows[0]["c"].ToString();
                }
                ds.Reset();
                if (query_ds != null)
                {
                    query_ds.Dispose();
                }
                query_ds = db_dts.ExeQueryToDs("SELECT  id, channel_id, area_no, alarm_time,create_time, " +
                    "case alarm_type when 1 then '高温报警' when 2 then '差温报警' when 3 then '区域温差报警' when  0 then '正常' else '未知报警' end alarm_type," +
                    " begin_pos, end_pos, case is_show when 0 then '未确认' when 1 then '已确认' else '误报' end  show_check FROM   hk_dts_real_alarm_info order by id desc;");
                //ds = query_ds;
                ViewData["ds"] = query_ds;
                //ds.Dispose();
            }
            else
            {
                string total_str = "select count(*) c from (select id from hk_dts_real_alarm_info where 1=1 ";
                string sel_str = "SELECT  id, channel_id, area_no, alarm_time,create_time, " +
                    "case alarm_type when 1 then '高温报警' when 2 then '差温报警' when 3 then '区域温差报警' when  0 then '正常' " +
                    " else '未知报警' end alarm_type,  begin_pos, end_pos,  case is_show when 0 then '未确认' when 1 then '已确认' else '误报' end" +
                    " show_check FROM  hk_dts_real_alarm_info where 1=1 ";

                int pa_nu = 0;
                if (start_date != null)
                {
                    if (start_date.Length > 0)
                    {

                        total_str = total_str + " and alarm_time>'" + start_date + "' ";
                        sel_str = sel_str + " and alarm_time>'" + start_date + "' ";
                        pa_nu = pa_nu + 1;
                    }
                }

                if (end_date != null)
                {
                    if (end_date.Length > 0)
                    {
                        total_str = total_str + " and alarm_time<'" + end_date + "' ";
                        sel_str = sel_str + " and alarm_time<'" + end_date + "' ";
                        pa_nu = pa_nu + 1;
                    }
                }

                if (areano != null)
                {
                    if (areano.Length > 0)
                    {
                        total_str = total_str + " and  area_no=" + areano;
                        sel_str = sel_str + " and area_no=" + areano;
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

                    if (alarmtype != "0")
                    {
                        if (alarmtype == "4") alarmtype = "0";
                        total_str = total_str + " and  alarm_type=" + alarmtype;
                        sel_str = sel_str + " and  alarm_type=" + alarmtype;

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
                sel_str = sel_str + "  order by id desc;";

                DataSet ds = db_dts.ExeQueryToDs(total_str);
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
                query_ds = db_dts.ExeQueryToDs(sel_str);
                //ds = query_ds;
                ViewData["ds"] = query_ds;

            }
            db_dts.Close();
            db_dts.Dispose();
            return PartialView();

        }

        public ActionResult Dtsfypage()
        {
            string curpage = Request.QueryString["npage"];
            ViewData["curpage"] = curpage;
            ViewData["ds"] = query_ds;
            return PartialView();
        }

        ////////////////////////////////////////////////////////////////
        public ActionResult Dtsdata()
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

        public ActionResult Dtsdataqy()
        {
            string start_date = Request.QueryString["startdate"];
            string end_date = Request.QueryString["enddate"];
            if (end_date != null)
            {
                end_date = end_date + " 23:59:59";
            }
            string ch_id = Request.QueryString["chid"];
            string idno = Request.QueryString["idno"];

            DataBase_Vib db_dts = new DataBase_Vib(3);
            db_dts.Open();
            if ((start_date == null) && (end_date == null) && (ch_id == null) && (idno == null))
            {
                DataSet ds = db_dts.ExeQueryToDs("select count(*) c from (select id from hk_dts_real_data_info) T;");
                if (ds != null)
                {
                    ViewBag.Vibcount = ds.Tables[0].Rows[0]["c"].ToString();
                }
                ds.Reset();
                if (query_ds != null)
                {
                    query_ds.Dispose();
                }
                query_ds = db_dts.ExeQueryToDs("SELECT  id, channel_id, left(point_len,8) dot_len, create_time FROM  hk_dts_real_data_info order by id desc;");
                //ds = query_ds;
                ViewData["ds"] = query_ds;
                //ds.Dispose();
            }
            else
            {
                string total_str = "select count(*) c from (select id from hk_dts_real_data_info where 1=1 ";
                string sel_str = "SELECT  id, channel_id, left(point_len,8) dot_len, create_time FROM  hk_dts_real_data_info where 1=1 ";

                int pa_nu = 0;
                if (start_date != null)
                {
                    if (start_date.Length > 0)
                    {

                        total_str = total_str + " and create_time>'" + start_date + "' ";
                        sel_str = sel_str + " and create_time>'" + start_date + "' ";
                        pa_nu = pa_nu + 1;
                    }
                }

                if (end_date != null)
                {
                    if (end_date.Length > 0)
                    {
                        total_str = total_str + " and create_time<'" + end_date + "' ";
                        sel_str = sel_str + " and create_time<'" + end_date + "' ";
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
                sel_str = sel_str + "  order by id desc;";

                DataSet ds = db_dts.ExeQueryToDs(total_str);
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
                query_ds = db_dts.ExeQueryToDs(sel_str);
                //ds = query_ds;
                ViewData["ds"] = query_ds;

            }
            db_dts.Close();
            db_dts.Dispose();
            return PartialView();
        }
        public ActionResult Dtsdfypage()
        {
            string curpage = Request.QueryString["npage"];
            ViewData["curpage"] = curpage;
            ViewData["ds"] = query_ds;
            return PartialView();
        }

        public JsonResult Getbarjson()
        {
            string eid = Request.QueryString["id"];
            string ch = Request.QueryString["ch"];
            ArrayList xAxisData = new ArrayList();
            ArrayList yAxisData = new ArrayList();
            DataBase_Vib db_dts = new DataBase_Vib(3);
            db_dts.Open();
            string sql_str = "";
            if (eid == null)
            {
                if (ch == null)
                {
                    sql_str = "select id, create_time, data,  point_len from hk_dts_real_data_info order by id desc limit 1;";
                }
                else
                {
                    sql_str = "select id, create_time, data,  point_len from hk_dts_real_data_info where channel_id=";
                    sql_str = sql_str + ch;
                    sql_str = sql_str+" order by id desc limit 1;";
                }
            }
            else
            {
                sql_str = "select id, create_time, data,  point_len from hk_dts_real_data_info where id=" + eid + ";";
            }
            DataSet ds = null;
            System.Data.DataRow dr=null;
            try
            {
                ds = db_dts.ExeQueryToDs(sql_str);
                dr = ds.Tables[0].Rows[0];
            }
            catch { }
            string r_id="";
            string r_data="";
            string r_rece_time;
           // string r_begin_pos;
            string r_dot_len="0";
            if (dr != null)
            {
                r_id = dr["id"].ToString();
                r_data = dr["data"].ToString();
                r_rece_time = dr["create_time"].ToString();
                //r_begin_pos = dr["begin_pos"].ToString();
                r_dot_len = dr["point_len"].ToString(); 
            }
            // double fiber_pos = Convert.ToDouble(r_begin_pos);
            double fiber_pos = 0;
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

                data_pos = r_data.IndexOf(":");
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
                 if (temp.IndexOf(".-") < 0)
                {
                    try
                    {

                        temp_value = Convert.ToDouble(temp);
                        if (temp_value > 20000) temp_value = 0;
                        
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

                if (t_id % 10 == 0)
                {
                    local_value_max = local_value_max / 10.0;
                    yAxisData.Add(local_value_max.ToString());

                    if (position_max == 0)
                    {
                        position_max = fiber_pos;
                    }
                    temp_str = Convert.ToString(position_max/100.00);
                    if (temp_str.Length > 8)
                    {
                        temp_str = temp_str.Substring(0, 8);
                    }
                    xAxisData.Add(temp_str);
                    local_value_max = 0;
                    position_max = 0;

                }
                if (t_id > 10000) break;

            }

            if (r_id.Length == 0)
            {
                yAxisData.Add("0");
                xAxisData.Add("0");
            }

            var result = new { Pos = xAxisData, Valu = yAxisData };
            db_dts.Close();
            db_dts.Dispose();
            ds.Reset();

            return Json(result, JsonRequestBehavior.AllowGet);

        }

        public ActionResult showhispop()
        {
            string id = Request.QueryString["rid"];
            string time = Request.QueryString["ctime"];

            DataBase_Vib db_dts = new DataBase_Vib(3);
            db_dts.Open();
            string sql_str = "";
            sql_str = "select id, create_time from hk_dts_real_data_info where create_time<='" + time + "' order by id desc limit 1;";
            DataSet ds = null;
            System.Data.DataRow dr = null;
            try
            {
                ds = db_dts.ExeQueryToDs(sql_str);
                dr = ds.Tables[0].Rows[0];
            }
            catch { }
            string r_id = "";
            if (dr != null)
            {
                r_id = dr["id"].ToString();
            }
            else
            {
                ds.Reset();
                sql_str = "select id, create_time from hk_dts_real_data_info where create_time>='" + time + "' order by id limit 1;";
                try
                {
                    ds = db_dts.ExeQueryToDs(sql_str);
                    dr = ds.Tables[0].Rows[0];
                }
                catch { }
                r_id = "";
                if (dr != null)
                {
                    r_id = dr["id"].ToString();
                }

            }


            ViewData["rid"] = r_id;
            ViewData["ctime"] = time;

            db_dts.Close();
            db_dts.Dispose();
            ds.Reset();
            return PartialView();
        }
       

    }
}