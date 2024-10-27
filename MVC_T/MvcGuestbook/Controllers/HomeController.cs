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
    public class HomeController : Controller
    {
        
        public ActionResult Index()
        {
            ViewBag.Username = HttpContext.User.Identity.Name;
            string Userrole = Request.QueryString["userrole"];
            if (Userrole != null)
            {
                Response.Cookies["userrole"].Value = Userrole;
                Response.Cookies["userrole"].Expires = DateTime.Now.AddDays(1);
                Response.Cookies["Logtime"].Value = DateTime.Now.ToString();
            }
            else 
           {
                Userrole = Request.QueryString.Get("userrole");
               // Userrole = Request.RequestContext.RouteData.Values["userrole"].ToString();
                if (Userrole != null)
                {
                    Response.Cookies["userrole"].Value = Userrole.ToString();
                    Response.Cookies["userrole"].Expires = DateTime.Now.AddDays(1);
                    Response.Cookies["Logtime"].Value = DateTime.Now.ToString();
                }
                else 
                {
                    if ((Request.Cookies["userrole"] != null) && (Request.Cookies["userrole"].Value != null))
                    {
                        Userrole = Request.Cookies["userrole"].Value;
                    }
                }
            }
            ViewBag.Displaynewbn = false;

            if (Userrole != null)
            {
                if (Userrole == "0")
                {
                    ViewBag.Displaynewbn = true;
                    ViewBag.logtime = Response.Cookies["Logtime"].Value;
                }
            }
            

            return View();
        }
       
        public ActionResult Vibalarm()
        {

            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            DataSet ds = db_vib.ExeQueryToDs("select count(*) c from (select id from hk_vib_event_detail where is_show=0) T;");
            if (ds!=null)
            {
                ViewBag.Vibcount = ds.Tables[0].Rows[0]["c"].ToString();
            }
            ds.Reset();
            ds = db_vib.ExeQueryToDs("select id, push_time, channel_id, center_pos, level from hk_vib_event_detail where is_show=0 order by id desc limit 3;");
            ViewData["ds"]=ds;
            ds.Dispose();

            db_vib.Close();
            db_vib.Dispose();
            return PartialView();
        }

        public ActionResult Vibfibalarm()
        {

            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            DataSet ds = db_vib.ExeQueryToDs("select count(*) c from (select id from  hk_fiber_event_detail where is_show=0 and fiber_stat<>'None') T;");
            if (ds != null)
            {
                ViewBag.Vibfibcount = ds.Tables[0].Rows[0]["c"].ToString();
            }
            ds.Reset();
            ds = db_vib.ExeQueryToDs("select id, push_time, channel_id, fiber_bk_len, case fiber_stat when 'Break' then '断纤' when 'NoFiber' " +
                    "then '光纤拔出' when 'None' then '光纤正常' when 'TooLong' then '光纤过长' end fiber_stat from hk_fiber_event_detail where is_show=0 and fiber_stat<>'None' order by id desc limit 3;");
            ViewData["ds"] = ds;
            ds.Dispose();

            db_vib.Close();
            db_vib.Dispose();
            return PartialView();
        }

        public ActionResult Botdaalarm()
        {

            DataBase_Vib db_botda = new DataBase_Vib(2);
            db_botda.Open();
            DataSet ds = db_botda.ExeQueryToDs("select count(*) c from (select id from hk_botda_alarm_info where is_show=0) T;");
            if (ds != null)
            {
                ViewBag.Botdacount = ds.Tables[0].Rows[0]["c"].ToString();
            }
            ds.Reset();
            ds = db_botda.ExeQueryToDs("select id, alarm_time, channel_id, cent_pos, max_value from hk_botda_alarm_info where is_show=0 order by id desc limit 3;");
            ViewData["ds"] = ds;
            ds.Dispose();

            db_botda.Close();
            db_botda.Dispose();
            return PartialView();
        }

        public ActionResult dtsalarm()
        {

            DataBase_Vib db_dts = new DataBase_Vib(3);
            db_dts.Open();
            DataSet ds = db_dts.ExeQueryToDs("select count(*) c from (select id from hk_dts_real_alarm_info where is_show=0) T;");
            if (ds != null)
            {
                ViewBag.Dtscount = ds.Tables[0].Rows[0]["c"].ToString();
            }
            ds.Reset();
            ds = db_dts.ExeQueryToDs("select id, alarm_time, channel_id, begin_pos, case alarm_type when 1 then '高温报警' when 2 then '差温报警' when 3 then '区域温差报警'  else '未知报警' end alarm_type, area_no, '0' as point_len from hk_dts_real_alarm_info where is_show=0 order by id desc limit 3;");
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
                temp_id=Convert.ToInt32( dr["id"].ToString());
                temp_time = dr["alarm_time"].ToString();
                temp_chid = dr["channel_id"].ToString();
                temp_begin_pos = Convert.ToDouble(dr["begin_pos"].ToString());
                temp_qureystr = "select channel_id, create_time, point_len from hk_dts_ch_def where create_time<'"+temp_time+"' and channel_id="+temp_chid+" order by id desc limit 1";
                ds_temp = db_dts.ExeQueryToDs(temp_qureystr);
                temp_pointlen = Convert.ToDouble(ds_temp.Tables[0].Rows[0]["point_len"].ToString());
                temp_begin_pos = temp_begin_pos * temp_pointlen/100;
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

        public ActionResult About()
        {
            ViewBag.Message = "Your application description page.";

            return View();
        }

        public ActionResult Vibdetail()
        {
            string alarm_id = Request.QueryString["id"];

            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            DataSet ds = db_vib.ExeQueryToDs("SELECT id, topic, channel_id, sensor_id, sample_id, level, possibility, " +
                                                            "center_pos, event_width, max_intensity, push_time  " +
                                                            "FROM hk_vib_event_detail  where id =" + alarm_id);
            ViewData["ds"] = ds;
            ds.Dispose();

            db_vib.Close();
            db_vib.Dispose();

            return PartialView();


        }

        public ActionResult Vibfibdetail()
        {
            string alarm_id = Request.QueryString["id"];

            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            DataSet ds = db_vib.ExeQueryToDs("SELECT hk_fiber_event_detail.id, hk_fiber_event_detail.topic," +
                                                            " hk_fiber_event_detail.channel_id, hk_fiber_event_detail.sensor_id, " +
                                                            "hk_fiber_event_detail.fiber_bk_len, case hk_fiber_event_detail.fiber_stat when 'Break' then '断纤' when 'NoFiber' " +
                                                            "then '光纤拔出' when 'None' then '光纤正常' when 'TooLong' then '光纤过长' end fiber_stat, " +
                                                            "hk_fiber_event_detail.push_time, hk_fiber_figure_id.fiber_type, hk_fiber_figure_id.fiber_producer, " +
                                                            "hk_fiber_figure_id.fiber_produce_date, hk_fiber_figure_id.fiber_len, hk_fiber_figure_id.fiber_annotation " +
                                                            "FROM hk_fiber_event_detail, hk_fiber_figure_id  where " + "hk_fiber_event_detail.id =" + alarm_id +
                                                            " and hk_fiber_event_detail.channel_id = hk_fiber_figure_id.channel");
            ViewData["ds"] = ds;
            ds.Dispose();

            db_vib.Close();
            db_vib.Dispose();

            return PartialView();


        }

        public ActionResult Botdadetail()
        {
            string alarm_id = Request.QueryString["id"];

            DataBase_Vib db_botda = new DataBase_Vib(2);
            db_botda.Open();
            DataSet ds = db_botda.ExeQueryToDs("SELECT id, device_name, channel_id, alarm_time,update_time,event_type,alarm_guid, max_value,limen_value, case alarm_format when 1 then '定值报警' when 2 then '定值报警' when 3 then '差值报警' when  4 then '故障' when 5 then" +
                "'故障恢复' else '未知报警' end alarm_type, begin_pos, end_pos, cent_pos from hk_botda_alarm_info where id=" + alarm_id);
            ViewData["ds"] = ds;
            ds.Dispose();

            db_botda.Close();
            db_botda.Dispose();

            return PartialView();

        }

        public ActionResult Dtsdetail()
        {
            string alarm_id = Request.QueryString["id"];

            DataBase_Vib db_dts = new DataBase_Vib(3);
            db_dts.Open();
            DataSet ds = db_dts.ExeQueryToDs("SELECT id,  channel_id, alarm_time,create_time, case alarm_type when 1 then '高温报警' when 2 then '差温报警' when 3 then '区域温差报警'  else '未知报警' end alarm_type, begin_pos, end_pos, area_no, create_time from hk_dts_real_alarm_info where id=" + alarm_id);
            ViewData["ds"] = ds;
            double begin_pos = Convert.ToDouble(ds.Tables[0].Rows[0]["begin_pos"].ToString());
            double end_pos = Convert.ToDouble(ds.Tables[0].Rows[0]["end_pos"].ToString());
            string m_date = ds.Tables[0].Rows[0]["create_time"].ToString();
            if ((m_date != null) && (m_date.Length > 0))
            {
                DataSet ds1 = db_dts.ExeQueryToDs("SELECT id,  channel_id, data,  point_len from hk_dts_real_data_info where create_time>='" + m_date+"' order by create_time limit 1");
                ////////////////////////////////////////////////////////////////////
                string r_data;
                r_data = ds1.Tables[0].Rows[0]["data"].ToString();
                string r_dot_len = ds1.Tables[0].Rows[0]["point_len"].ToString();
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
                            if (temp_value > 10000) temp_value = 0;

                        }
                        catch
                        {
                            int test = 1;
                        }
                    }

                    // DataRow d = dt.NewRow();
                    t_id = t_id + 1;
                    fiber_pos = fiber_pos + fiber_dot_len;



                    if ((t_id >= begin_pos)&&(t_id<=end_pos))
                    {
                        if (System.Math.Abs(temp_value) > System.Math.Abs(local_value_max))
                        {
                            local_value_max = temp_value;
                            id_max = t_id;
                            position_max = fiber_pos;
                        }

                      

                        if (position_max == 0)
                        {
                            position_max = fiber_pos;
                        }
                        temp_str = Convert.ToString(position_max / 100.00);
                        if (temp_str.Length > 8)
                        {
                            temp_str = temp_str.Substring(0, 8);
                        }

                    }
                    if (t_id > end_pos) break;
                    if (t_id > 10000) break;

                }

               local_value_max = local_value_max / 10.0;
               ViewBag.max_tmp = Convert.ToString(local_value_max);
               ViewBag.dot_len = fiber_dot_len;

               ds1.Dispose();
                //////////////////////////////////////////////////////
            }


            


            ds.Dispose();
            

           

            db_dts.Close();
            db_dts.Dispose();

            return PartialView();


        }

        public ActionResult Setvibflag()
        {
            string alarm_id = Request.QueryString["id"];
            string vib_flag= Request.QueryString["flag"];
            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            string sql_str="";
            if (vib_flag=="1")
            {
                sql_str = "update hk_vib_event_detail set is_show=1 where id=" + alarm_id + ";"; 
            }
            if (vib_flag == "2")
            {
                sql_str = "update hk_vib_event_detail set is_show=2 where id=" + alarm_id + ";";
            }

            db_vib.ExeNoQuery(sql_str);
      


            db_vib.Close();
            db_vib.Dispose();


            return new EmptyResult();
        }

        public ActionResult Setvibfibflag()
        {
            string alarm_id = Request.QueryString["id"];
            string vib_flag = Request.QueryString["flag"];
            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            string sql_str = "";
            if (vib_flag == "1")
            {
                sql_str = "update hk_fiber_event_detail set is_show=1 where id=" + alarm_id + ";";
            }
            if (vib_flag == "2")
            {
                sql_str = "update hk_fiber_event_detail set is_show=2 where id=" + alarm_id + ";";
            }

            db_vib.ExeNoQuery(sql_str);



            db_vib.Close();
            db_vib.Dispose();


            return new EmptyResult();

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

        public ActionResult Setdtsflag()
        {
            string alarm_id = Request.QueryString["id"];
            string vib_flag = Request.QueryString["flag"];
            DataBase_Vib db_dts = new DataBase_Vib(3);
            db_dts.Open();
            string sql_str = "";
            if (vib_flag == "1")
            {
                sql_str = "update hk_dts_real_alarm_info set is_show=1 where id=" + alarm_id + ";";
            }
            if (vib_flag == "2")
            {
                sql_str = "update hk_dts_real_alarm_info set is_show=2 where id=" + alarm_id + ";";
            }

            db_dts.ExeNoQuery(sql_str);



            db_dts.Close();
            db_dts.Dispose();


            return new EmptyResult();
        }

        public ActionResult Contact()
        {
            ViewBag.Message = "Your contact page.";

            return View();
        }
        public ActionResult GetJavaScript()        
        {
            return JavaScript("alert('OK')");
        }
        public ActionResult Bigscreen()
        {
            string vibip = System.Web.Configuration.WebConfigurationManager.AppSettings["VIB_CURVE_URL"];
            ViewBag.Viburl = vibip;
            return View();
        }
        /// <summary>
        /// ***************/////////////////////////////////////////////////////////////////////*************************************88
        /// </summary>
        /// <returns></returns>
        public ActionResult BigscreenAlarm()
        {

            DataBase_Vib db_vib = new DataBase_Vib(1);
            string date_s="";
            string date_temp="";
            ViewData["type"] = Convert.ToString(0);

            db_vib.Open();
            DataSet ds = db_vib.ExeQueryToDs("select count(*) c from (select id from  hk_fiber_event_detail where is_show=0 and fiber_stat<>'None') T;");
            if (ds != null)
            {
                //ViewBag.Vibfibcount = ds.Tables[0].Rows[0]["c"].ToString();
                //}
                ds.Reset();
                ds = null;
                ds = db_vib.ExeQueryToDs("select id, push_time, channel_id, fiber_bk_len, case fiber_stat when 'Break' then '断纤' when 'NoFiber' " +
                        "then '光纤拔出' when 'None' then '光纤正常' when 'TooLong' then '光纤过长' end fiber_stat from hk_fiber_event_detail where is_show=0 and fiber_stat<>'None' order by id desc limit 1;");
                ViewData["ds"] = ds;
                date_s = ds.Tables[0].Rows[0]["push_time"].ToString();
              
                ViewData["type"] = Convert.ToString(1);
                ds.Dispose();

            }
            db_vib.Close();
            db_vib.Dispose();
            ///////////////////////////////////////////////////////////////////////////////////////

            db_vib.Open();
            ds = db_vib.ExeQueryToDs("select count(*) c from (select id from  hk_vib_event_detail where is_show=0 ) T;");

            if (ds != null)
            {
               ds.Reset();
               ds = null;
               ds = db_vib.ExeQueryToDs("SELECT id, topic, channel_id, sensor_id, sample_id, level, possibility, " +
                                                                   "center_pos, event_width, max_intensity, push_time " +
                                                                   "FROM hk_vib_event_detail   where is_show=0  order by id desc limit 1;");               
                date_temp = ds.Tables[0].Rows[0]["push_time"].ToString();
               if (string.Compare(date_temp,date_s)>0)
               {
                    ViewData["ds"] = ds;
                    ViewData["type"] = Convert.ToString(2);
                    date_s = date_temp;
               }
               ds.Dispose();

            }
          
            db_vib.Close();
            db_vib.Dispose();
          /////////////////////////////////////////////////////////////////////


          DataBase_Vib db_botda = new DataBase_Vib(2);
          db_botda.Open();
          ds = db_botda.ExeQueryToDs("select count(*) c from (select id from  hk_botda_alarm_info where is_show=0) T;");
         
          if (ds != null)
          {
              ds.Reset();
              ds = null;
              ds = db_botda.ExeQueryToDs("SELECT id, device_name, channel_id, alarm_time,update_time,event_type,alarm_guid, max_value,limen_value, case alarm_format when 1 then '定值报警' when 2 then '定值报警' when 3 then '差值报警' when  4 then '故障' when 5 then" +
              "'故障恢复' else '未知报警' end alarm_type, begin_pos, end_pos, cent_pos from hk_botda_alarm_info  where is_show=0 order by id desc limit 1;");
              
              date_temp = ds.Tables[0].Rows[0]["update_time"].ToString();
              if (string.Compare(date_temp, date_s) > 0)
              {
                   ViewData["ds"] = ds;
                   ViewData["type"] = Convert.ToString(3);
                   date_s = date_temp;
              }
              ds.Dispose();
          }
          db_botda.Close();
          db_botda.Dispose();

          //////////////////////////////////////////////////////////////////////////////////

          DataBase_Vib db_dts = new DataBase_Vib(3);
          db_dts.Open();
          ds = db_dts.ExeQueryToDs("select count(*) c from (select id from  hk_dts_real_alarm_info where is_show=0 ) T;");
          if (ds != null)
          {
              ds.Reset();
              ds = db_dts.ExeQueryToDs("SELECT id,  channel_id, alarm_time,create_time, case alarm_type when 1 then '高温报警' when 2 then '差温报警' when 3 then '区域温差报警'  else '未知报警' end alarm_type, begin_pos, end_pos, area_no, create_time from hk_dts_real_alarm_info  where is_show=0 order by id desc limit 1;");
              
              date_temp = ds.Tables[0].Rows[0]["create_time"].ToString();
              if (string.Compare(date_temp, date_s) > 0)
              {
                  ViewData["ds"] = ds;
                  ViewData["type"] = Convert.ToString(4);
                  date_s = date_temp;
              }
              ds.Dispose();
          }
          db_dts.Close();
          db_dts.Dispose();
   
            /*
            double begin_pos = Convert.ToDouble(ds.Tables[0].Rows[0]["begin_pos"].ToString());
            double end_pos = Convert.ToDouble(ds.Tables[0].Rows[0]["end_pos"].ToString());
            string m_date = ds.Tables[0].Rows[0]["create_time"].ToString();
            */

            return PartialView();


        }

        public ActionResult Showmap()
        {
            string alarm_id = Request.QueryString["id"];
            string alarm_type = Request.QueryString["type"];
            ViewData["id"] = alarm_id;
            ViewData["type"] = alarm_type;
            ViewData["x"] = 0;
            ViewData["y"] = 0;
            DataBase_Vib db= null;
            string sql_str = "";
            DataSet ds = null;
            string pos = "";
            double int_pos = 0;

            if (alarm_type == "1")
            {
                db= new DataBase_Vib(1);
                db.Open();
                sql_str = "select fiber_bk_len from hk_fiber_event_detail where id="+ alarm_id +";";
                ds = db.ExeQueryToDs(sql_str);
                pos = ds.Tables[0].Rows[0]["fiber_bk_len"].ToString();


            }
            else if (alarm_id == "2")
            {
                db = new DataBase_Vib(1);
                db.Open();
                sql_str = "select center_pos from hk_vib_event_detail where id=" + alarm_id + ";";
                ds = db.ExeQueryToDs(sql_str);
                pos = ds.Tables[0].Rows[0]["center_pos"].ToString();
            }
            else if (alarm_id == "3")
            {
                db = new DataBase_Vib(2);
                db.Open();
                sql_str = "select cent_pos from hk_botda_alarm_info where id=" + alarm_id + ";";
                ds = db.ExeQueryToDs(sql_str);
                pos = ds.Tables[0].Rows[0]["cent_pos"].ToString();
            }
            else if (alarm_id == "4")
            {

                db = new DataBase_Vib(3);
                db.Open();
                sql_str = "select begin_pos from hk_dts_real_alarm_info where id=" + alarm_id + ";";
                ds = db.ExeQueryToDs(sql_str);
                pos = ds.Tables[0].Rows[0]["begin_pos"].ToString();
            }

            if (pos.Length > 0)
            {
                int_pos = Convert.ToDouble(pos);
                if ((int_pos > 0) && (int_pos < 500))
                {
                    ViewData["x"] = "121.441205";
                    ViewData["y"] = "31.103392";
                }
                else if ((int_pos > 499) && (int_pos < 1000)) 
                {
                    ViewData["x"] = "121.5";
                    ViewData["y"] = "31.11";
                }
                else if ((int_pos > 999) && (int_pos < 1500))
                {
                    ViewData["x"] = "121.6";
                    ViewData["y"] = "31.2";
                }
                else if ((int_pos > 1499) && (int_pos < 2000))
                {
                    ViewData["x"] = "121.7";
                    ViewData["y"] = "31.3";
                }
                else if ((int_pos > 1999) && (int_pos < 2500))
                {
                    ViewData["x"] = "121.8";
                    ViewData["y"] = "31.3";
                }
                else if ((int_pos > 2499) && (int_pos < 3000))
                {
                    ViewData["x"] = "121.9";
                    ViewData["y"] = "31.4";
                }
                else if ((int_pos > 2999) && (int_pos < 3500))
                {
                    ViewData["x"] = "121.9";
                    ViewData["y"] = "32.0";
                }
                else if ((int_pos > 3499) && (int_pos < 4000))
                {
                    ViewData["x"] = "122.0";
                    ViewData["y"] = "32.1";
                }

            }
            if (ds != null)
            {
                ds.Dispose();
            }
            if (db != null)
            {
                db.Close();
                db.Dispose();      
            }

            return PartialView();

        }

        public JsonResult Getbsdata()
        {
            string ch = Request.QueryString["ch"];
            ArrayList DataList = new ArrayList();
            ArrayList NameList = new ArrayList();
            if (ch == null)
            {
                ch = "1";
            }
            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            string sql_str = "select count(*) c from (select id from hk_vib_event_detail where is_show=0 and channel_id="+ ch+ ") T;";

            DataSet ds = null;
            System.Data.DataRow dr = null;
            try
            {
                ds = db_vib.ExeQueryToDs(sql_str);
                dr = ds.Tables[0].Rows[0];
            }
            catch { }
            string n_count = "";
            try
            {
                ds = db_vib.ExeQueryToDs(sql_str);
                dr = ds.Tables[0].Rows[0];
            }
            catch { }
            if (dr != null)
            {
                n_count = dr["c"].ToString();
            }
            DataList.Add(n_count);
            ds.Reset();
            sql_str = "select count(*) c from (select id from hk_fiber_event_detail where is_show=0 and fiber_stat<>'None' and channel_id=" + ch + ") T;";
            ds = null;
            dr = null;
            try
            {
                ds = db_vib.ExeQueryToDs(sql_str);
                dr = ds.Tables[0].Rows[0];
            }
            catch { }
            if (dr != null)
            {
                n_count = dr["c"].ToString();
            }
            DataList.Add(n_count);
            db_vib.Close();
            db_vib.Dispose();
            ds.Reset();

            DataBase_Vib db_bot = new DataBase_Vib(2);

            
            db_bot.Open();
            sql_str = "select count(*) c from (select id from hk_botda_alarm_info where  is_show=0 and channel_id=" + ch + ") T;";

            ds = null;
            dr = null;
            try
            {
                ds = db_bot.ExeQueryToDs(sql_str);
                dr = ds.Tables[0].Rows[0];
            }
            catch { }
            if (dr != null)
            {
                n_count = dr["c"].ToString();
            }
            DataList.Add(n_count);
            db_bot.Close();
            db_bot.Dispose();
            ds.Reset();


            DataBase_Vib db_dts = new DataBase_Vib(3);


            db_dts.Open();
            sql_str = "select count(*) c from (select id from hk_dts_real_alarm_info where  is_show=0 and channel_id=" + ch + ") T;";

            ds = null;
            dr = null;
            try
            {
                ds = db_dts.ExeQueryToDs(sql_str);
                dr = ds.Tables[0].Rows[0];
            }
            catch { }
            if (dr != null)
            {
                n_count = dr["c"].ToString();
            }
            DataList.Add(n_count);
            db_dts.Close();
            db_dts.Dispose();
            ds.Reset();

            string  username = HttpContext.User.Identity.Name;
            //NameList.Add(username);
            DataList.Add(username);
            var result = new { n_alarm = DataList };
            return Json(result, JsonRequestBehavior.AllowGet);

        }

        /// //////////////////////////////////////////////////////////////////////////////

        public JsonResult Getpiejson()
        {
            string n_count = "";
            ArrayList xAxisData = new ArrayList();
            ArrayList yAxisData = new ArrayList();

            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            string sql_str = "select count(*) c from (select id from hk_vib_event_detail where is_show=0) T;";
            DataSet ds = null;
            System.Data.DataRow dr = null;
            try
            {
                ds = db_vib.ExeQueryToDs(sql_str);
                dr = ds.Tables[0].Rows[0];
            }
            catch
            { }
            
            if (dr != null)
            {
                n_count = dr["c"].ToString();
            }
            xAxisData.Add("振动报警");
            yAxisData.Add(n_count);

            ds.Reset();
            sql_str = "select count(*) c from (select id from hk_fiber_event_detail where is_show=0 and fiber_stat<>'None') T;";
            ds = null;
            dr = null;
            try
            {
                ds = db_vib.ExeQueryToDs(sql_str);
                dr = ds.Tables[0].Rows[0];
            }
            catch { }
            if (dr != null)
            {
                n_count = dr["c"].ToString();
            }
            xAxisData.Add("光纤状态报警");
            yAxisData.Add(n_count);

            db_vib.Close();
            db_vib.Dispose();
            ds.Reset();


            DataBase_Vib db_bot = new DataBase_Vib(2);


            db_bot.Open();
            sql_str = "select count(*) c from (select id from hk_botda_alarm_info where  is_show=0) T;";

            ds = null;
            dr = null;
            try
            {
                ds = db_bot.ExeQueryToDs(sql_str);
                dr = ds.Tables[0].Rows[0];
            }
            catch { }
            if (dr != null)
            {
                n_count = dr["c"].ToString();
            }
            xAxisData.Add("BOTDA应变报警");
            yAxisData.Add(n_count);
            db_bot.Close();
            db_bot.Dispose();
            ds.Reset();

            DataBase_Vib db_dts = new DataBase_Vib(3);

            db_dts.Open();
            sql_str = "select count(*) c from (select id from hk_dts_real_alarm_info where  is_show=0) T;";
            ds = null;
            dr = null;
            try
            {
                ds = db_dts.ExeQueryToDs(sql_str);
                dr = ds.Tables[0].Rows[0];
            }
            catch { }
            if (dr != null)
            {
                n_count = dr["c"].ToString();
            }
            xAxisData.Add("DTS温度报警");
            yAxisData.Add(n_count);
            db_dts.Close();
            db_dts.Dispose();
            ds.Reset();

            var result = new { Format = xAxisData, Num = yAxisData };
            return Json(result, JsonRequestBehavior.AllowGet);

        }
    }
}