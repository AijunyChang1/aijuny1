using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Data.Odbc;
using System.Data;

namespace MvcGuestbook.Controllers
{
    public class VibController : Controller
    {
        // GET: Vib
        static DataSet query_ds { get; set; }

        public ActionResult Index()
        {
            string Userrole= Request.Cookies["userrole"].Value;
            ViewBag.Username = HttpContext.User.Identity.Name;
            ViewBag.Displaynewbn = false;

            if (Userrole != null)
            {
                if (Userrole == "0")
                {
                    ViewBag.Displaynewbn = true;
                }
            }
            string vibip = System.Web.Configuration.WebConfigurationManager.AppSettings["VIB_CURVE_URL"];
            ViewBag.Viburl = vibip;
            return View();
        }

        public ActionResult Vibalarm()
        {

            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            DataSet ds = db_vib.ExeQueryToDs("select count(*) c from (select id from hk_vib_event_detail where is_show=0) T;");
            if (ds != null)
            {
                ViewBag.Vibcount = ds.Tables[0].Rows[0]["c"].ToString();
            }
            ds.Reset();
            ds = db_vib.ExeQueryToDs("select id, push_time, channel_id, center_pos, level, sample_id, possibility, event_width, max_intensity from hk_vib_event_detail where is_show=0 order by id desc limit 5;");
            ViewData["ds"] = ds;
            ds.Dispose();

            db_vib.Close();
            db_vib.Dispose();
            return PartialView();
        }

        public ActionResult Vibfibalarm()
        {

            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            DataSet ds = db_vib.ExeQueryToDs("select count(*) c from (select id from hk_fiber_event_detail where is_show=0 and fiber_stat<>'None') T;");
            if (ds != null)
            {
                ViewBag.Vibfibcount = ds.Tables[0].Rows[0]["c"].ToString();
            }
            ds.Reset();
            ds = db_vib.ExeQueryToDs("select id, push_time, channel_id, fiber_bk_len, case fiber_stat when 'Break' then '断纤' when 'NoFiber' " +
                    "then '光纤拔出' when 'None' then '光纤正常' when 'TooLong' then '光纤过长' end fiber_stat from hk_fiber_event_detail where is_show=0 and fiber_stat<>'None' order by id desc limit 5;");
            ViewData["ds"] = ds;
            ds.Dispose();

            db_vib.Close();
            db_vib.Dispose();
            return PartialView();
        }

        public ActionResult Setvibflag()
        {
            string alarm_id = Request.QueryString["id"];
            string vib_flag = Request.QueryString["flag"];
            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            string sql_str = "";
            if (vib_flag == "1")
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

        public ActionResult Setfibflag()
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
        //////////////////////////////////////////////////////////////
        public ActionResult Vibhis()
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

        public ActionResult Vibhisquery()
        {

            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            DataSet ds = db_vib.ExeQueryToDs("select count(*) c from (select id from hk_vib_event_detail) T;");
            if (ds != null)
            {
                ViewBag.Vibcount = ds.Tables[0].Rows[0]["c"].ToString();
            }
            ds.Reset();
            if (query_ds != null)
            {
                query_ds.Dispose();
            }
            query_ds = db_vib.ExeQueryToDs("select id,  push_time, first_push_time, last_push_time, channel_id, sensor_id, center_pos, level, sample_id, sample_name, possibility, event_width, max_intensity, topic, case is_show when 0 then '未确认' when 1 then '已确认' else '误报' end show_check from hk_vib_event_detail  order by id desc limit 5000;");
            //ds = query_ds;
            ViewData["ds"] = query_ds;
            //ds.Dispose();

            db_vib.Close();
            db_vib.Dispose();
            return PartialView();
        }
        public ActionResult Queryvibrs()
        {

            string start_date = Request.QueryString["startdate"];
            string end_date = Request.QueryString["enddate"];
            if (end_date != null)
            {
                end_date = end_date + " 23:59:59";
            }
            string ch_id = Request.QueryString["chid"];
            string stats = Request.QueryString["stat"];
            string levl = Request.QueryString["level"];
            string total_str = "select count(*) c from (select id from hk_vib_event_detail ";
               
            string sel_str = "select id,  push_time, first_push_time, last_push_time, channel_id, sensor_id, " +
                             "center_pos, level, sample_id, sample_name, possibility, event_width, max_intensity, " +
                             "topic, case is_show when 0 then '未确认' when 1 then '已确认' else '误报' end show_check from hk_vib_event_detail ";
           
            int pa_nu = 0;
            if (start_date != null)
            {
                if (start_date.Length > 0)
                {
                    if (pa_nu == 0)
                    {
                        total_str = total_str + " where push_time>'" + start_date + "' ";
                        sel_str = sel_str + " where push_time>'" + start_date + "' ";
                    }
                    else
                    {
                        total_str = total_str + " and push_time>'" + start_date + "' ";
                        sel_str = sel_str + " and push_time>'" + start_date + "' ";
                    }
                    pa_nu = pa_nu + 1;
                }
            }

            if (end_date != null)
            {
                if (end_date.Length > 0)
                {
                    if (pa_nu == 0)
                    {
                        total_str = total_str + " where push_time<'" + end_date + "' ";
                        sel_str = sel_str + " where push_time<'" + end_date + "' ";
                    }
                    else
                    {
                        total_str = total_str + " and push_time<'" + end_date + "' ";
                        sel_str = sel_str + " and push_time<'" + end_date + "' ";
                    }
                    pa_nu = pa_nu + 1;
                }
            }

            if (ch_id != null)
            {
                if (ch_id.Length > 0)
                {
                    if (pa_nu == 0)
                    {
                        total_str = total_str + " where channel_id=" + ch_id;
                        sel_str = sel_str + " where channel_id=" + ch_id;
                    }
                    else
                    {
                        total_str = total_str + " and  channel_id=" + ch_id;
                        sel_str = sel_str + " and channel_id=" + ch_id;
                    }
                    pa_nu = pa_nu + 1;
                }
            }

            if (levl != null)
            {
                if (levl.Length > 0)
                {
                    if (pa_nu == 0)
                    {
                        total_str = total_str + " where level=" + levl;
                        sel_str = sel_str + " where level=" + levl;
                    }
                    else
                    {
                        total_str = total_str + " and  level=" + levl;
                        sel_str = sel_str + " and  level=" + levl;
                    }
                    pa_nu = pa_nu + 1;
                }
            }

            if (stats != null)
            {
                if (stats.Length > 0)
                {
                    if (stats != "0")
                    {
                        if (pa_nu == 0)
                        {
                            if (stats == "1")
                            {
                                total_str = total_str + " where is_show=1 ";
                                sel_str = sel_str + " where is_show=1 ";
                            }
                            else if (stats == "2")
                            {
                                total_str = total_str + " where is_show=0 ";
                                sel_str = sel_str + " where is_show=0 ";
                            }
                            else if (stats == "3")
                            {
                                total_str = total_str + " where is_show=2 ";
                                sel_str = sel_str + " where is_show=2 ";
                            }
                        }
                        else
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
                        }
                        pa_nu = pa_nu + 1;
                    }
                    
                }
            }
            total_str = total_str +  ") T";
            sel_str = sel_str + " order by id desc limit 5000;";

            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();


            DataSet ds = db_vib.ExeQueryToDs(total_str);
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
            query_ds = db_vib.ExeQueryToDs(sel_str);
            //ds = query_ds;
            ViewData["ds"] = query_ds;
            //ds.Dispose();

            db_vib.Close();
            db_vib.Dispose();
            return PartialView();
        }

        public ActionResult vibfypage()
        {
            string curpage = Request.QueryString["npage"];
            ViewData["curpage"] = curpage;
            ViewData["ds"] = query_ds;
            return PartialView();
        }

        ////////////////////////////////////////////////////////////
        public ActionResult Fibhis()
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


        public ActionResult Fibhisquery()
        {
            string start_date = Request.QueryString["startdate"];
            string end_date = Request.QueryString["enddate"];
            if (end_date != null)
            {
                end_date = end_date + " 23:59:59";
            }
            string ch_id = Request.QueryString["chid"];
            string stats = Request.QueryString["stat"];
            string fibstat = Request.QueryString["fibstat"];


            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            if ((start_date == null) && (end_date == null) && (ch_id == null) && (stats == null) && (fibstat == null))
            {
                DataSet ds = db_vib.ExeQueryToDs("select count(*) c from (select id from hk_fiber_event_detail) T;");
                if (ds != null)
                {
                    ViewBag.Vibcount = ds.Tables[0].Rows[0]["c"].ToString();
                }
                ds.Reset();
                if (query_ds != null)
                {
                    query_ds.Dispose();
                }
                query_ds = db_vib.ExeQueryToDs("select id,  push_time, topic, channel_id, sensor_id, case fiber_stat when 'Break' then '断纤' when 'NoFiber' " +
                    "then '光纤拔出' when 'None' then '光纤正常' when 'TooLong' then '光纤过长' end fiber_stat, fiber_bk_len, case is_show when 0 then '未确认' when 1 then '已确认' else '误报' end show_check from hk_fiber_event_detail  order by id desc;");
                //ds = query_ds;
                ViewData["ds"] = query_ds;
                //ds.Dispose();
            }
            else
            {
                 string total_str = "select count(*) c from (select id from hk_fiber_event_detail ";

                 string sel_str = "select id,  push_time, topic, channel_id, sensor_id, " +
                                 "case fiber_stat when 'Break' then '断纤' when 'NoFiber' then '光纤拔出' when 'None' then '光纤正常' when 'TooLong' then '光纤过长' end fiber_stat, " +
                                 " fiber_bk_len, case is_show when 0 then '未确认' when 1 then '已确认' else '误报' end show_check from hk_fiber_event_detail ";

                int pa_nu = 0;
                if (start_date != null)
                {
                    if (start_date.Length > 0)
                    {
                        if (pa_nu == 0)
                        {
                            total_str = total_str + " where push_time>'" + start_date + "' ";
                            sel_str = sel_str + " where push_time>'" + start_date + "' ";
                        }
                        else
                        {
                            total_str = total_str + " and push_time>'" + start_date + "' ";
                            sel_str = sel_str + " and push_time>'" + start_date + "' ";
                        }
                        pa_nu = pa_nu + 1;
                    }
                }

                if (end_date != null)
                {
                    if (end_date.Length > 0)
                    {
                        if (pa_nu == 0)
                        {
                            total_str = total_str + " where push_time<'" + end_date + "' ";
                            sel_str = sel_str + " where push_time<'" + end_date + "' ";
                        }
                        else
                        {
                            total_str = total_str + " and push_time<'" + end_date + "' ";
                            sel_str = sel_str + " and push_time<'" + end_date + "' ";
                        }
                        pa_nu = pa_nu + 1;
                    }
                }

                if (ch_id != null)
                {
                    if (ch_id.Length > 0)
                    {
                        if (pa_nu == 0)
                        {
                            total_str = total_str + " where channel_id=" + ch_id;
                            sel_str = sel_str + " where channel_id=" + ch_id;
                        }
                        else
                        {
                            total_str = total_str + " and  channel_id=" + ch_id;
                            sel_str = sel_str + " and channel_id=" + ch_id;
                        }
                        pa_nu = pa_nu + 1;
                    }
                }

                if (fibstat != null)
                {
                    if (fibstat.Length > 0)
                    {
                        string stat_str = "";
                        if (fibstat == "1")
                        {
                            stat_str = "Break";
                        }
                        else if (fibstat == "2")
                        {
                            stat_str = "NoFiber";
                        }
                        else if (fibstat == "3")
                        {
                            stat_str = "TooLong";
                        }
                        else if (fibstat == "4")
                        {
                            stat_str = "None";
                        }

                        if (pa_nu == 0)
                        {
                            total_str = total_str + " where fiber_stat='" + stat_str +"' ";
                            sel_str = sel_str + " where fiber_stat='" + stat_str + "' ";
                        }
                        else
                        {
                            total_str = total_str + " and  fiber_stat='" + stat_str + "' ";
                            sel_str = sel_str + " and  fiber_stat='" + stat_str + "' ";
                        }
                        pa_nu = pa_nu + 1;
                    }
                }

                if (stats != null)
                {
                    if (stats.Length > 0)
                    {
                        if (stats != "0")
                        {
                            if (pa_nu == 0)
                            {
                                if (stats == "1")
                                {
                                    total_str = total_str + " where is_show=1 ";
                                    sel_str = sel_str + " where is_show=1 ";
                                }
                                else if (stats == "2")
                                {
                                    total_str = total_str + " where is_show=0 ";
                                    sel_str = sel_str + " where is_show=0 ";
                                }
                                else if (stats == "3")
                                {
                                    total_str = total_str + " where is_show=2 ";
                                    sel_str = sel_str + " where is_show=2 ";
                                }
                            }
                            else
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
                            }
                            pa_nu = pa_nu + 1;
                        }

                    }
                }

                total_str = total_str + ") T";
                sel_str = sel_str + "  order by id desc;";

                DataSet ds = db_vib.ExeQueryToDs(total_str);
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
                query_ds = db_vib.ExeQueryToDs(sel_str);
                //ds = query_ds;
                ViewData["ds"] = query_ds;

            }
            db_vib.Close();
            db_vib.Dispose();
            return PartialView();
        }


        public ActionResult Fibfypage()
        {
            string curpage = Request.QueryString["npage"];
            ViewData["curpage"] = curpage;
            ViewData["ds"] = query_ds;
            return PartialView();
        }

    }
}