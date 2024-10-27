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
    public class FBGController : Controller
    {
        // GET: FBG
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

        public ActionResult Loaddev()
        {
            DataBase_Vib db_fbg = new DataBase_Vib(5);
            db_fbg.Open();
            DataSet ds = db_fbg.ExeQueryToDs("select distinct dev_id from hk_fbg_real_data_info;");
            ViewData["ds"] = ds;


            return PartialView();
        }

        public ActionResult Loaddev1()
        {
            DataBase_Vib db_fbg = new DataBase_Vib(5);
            db_fbg.Open();
            DataSet ds = db_fbg.ExeQueryToDs("select distinct dev_id from hk_fbg_real_data_info;");
            ViewData["ds"] = ds;


            return PartialView();
        }

        public ActionResult LoadSor()
        {
            string dev_id = Request.QueryString["dev"];
            DataBase_Vib db_fbg = new DataBase_Vib(5);
            db_fbg.Open();
            DataSet ds = db_fbg.ExeQueryToDs("select distinct sor_code, dev_id from hk_fbg_real_data_info where dev_id='"+dev_id+"';");
            ViewData["ds"] = ds;
            ViewData["dev"] = dev_id;

            return PartialView();
        }
        public ActionResult Fbgdata()
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


        public ActionResult Fbgdataqy()
        {
            string start_date = Request.QueryString["startdate"];
            string end_date = Request.QueryString["enddate"];
            query_ds=null;
            if (end_date != null)
            {
                end_date = end_date + " 23:59:59";
            }
            string dev_id = Request.QueryString["devid"];
            string sensor_no = Request.QueryString["sorno"];

            DataBase_Vib db_fbg= new DataBase_Vib(5);
            db_fbg.Open();
            if ((start_date == null) && (end_date == null) && (dev_id == null) && (sensor_no == null))
            {
                DataSet ds = db_fbg.ExeQueryToDs("select count(*) c from (select id from hk_fbg_real_data_info) T;");
                if (ds != null)
                {
                    ViewBag.Vibcount = ds.Tables[0].Rows[0]["c"].ToString();
                }
                ds.Reset();
                if (query_ds != null)
                {
                    query_ds.Dispose();
                }
                query_ds = db_fbg.ExeQueryToDs("SELECT  id, dev_id,  create_time,sor_code,left(data,10) data  FROM hk_fbg_real_data_info order by id desc limit 5000;");
                //ds = query_ds;
                ViewData["ds"] = query_ds;
                //ds.Dispose();
            }
            else
            {
                string total_str = "select count(*) c from (select id from hk_fbg_real_data_info where 1=1 ";
                string sel_str = "SELECT  id, dev_id,  create_time,sor_code,left(data,10) data  FROM  hk_fbg_real_data_info where 1=1 ";

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

                if (dev_id != null)
                {
                    if (dev_id.Length > 0)
                    {

                        total_str = total_str + " and  dev_id  like '%" + dev_id+ "%'";
                        sel_str = sel_str + " and  dev_id  like '%" + dev_id + "%'";
                        pa_nu = pa_nu + 1;
                    }
                }
                /*
                 if (idno != null)
                 {
                     if (idno.Length > 0)
                     {

                         total_str = total_str + " and  id=" + idno;
                         sel_str = sel_str + " and  id=" + idno;

                         pa_nu = pa_nu + 1;
                     }
                 }
                */
                if (sensor_no != null)
                {
                    if (sensor_no.Length > 0)
                    {

                        total_str = total_str + " and  sor_code like '%" + sensor_no +"%'";
                        sel_str = sel_str + " and  sor_code like '%" + sensor_no + "%'";

                        pa_nu = pa_nu + 1;
                    }
                }


                total_str = total_str + ") T";
                sel_str = sel_str + "  order by id desc limit 5000;";

                DataSet ds = db_fbg.ExeQueryToDs(total_str);
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
                query_ds = db_fbg.ExeQueryToDs(sel_str);
                //ds = query_ds;
                ViewData["ds"] = query_ds;

            }
            db_fbg.Close();
            db_fbg.Dispose();
            return PartialView();

        }

        public ActionResult Fbgfypage()
        {
            string curpage = Request.QueryString["npage"];
            ViewData["curpage"] = curpage;
            ViewData["ds"] = query_ds;
            return PartialView();
        }
        ////////////
        ///

        public JsonResult Getbarjson()
        {
            string dev = Request.QueryString["dev"];
            string sid = Request.QueryString["sid"];
            string cnum = Request.QueryString["chartN"];
            ArrayList xAxisData = new ArrayList();
            ArrayList yAxisData = new ArrayList();
            ArrayList zAxisData = new ArrayList();
            zAxisData.Add(cnum);
            DataBase_Vib db_fbg= new DataBase_Vib(5);
            db_fbg.Open();
            string sql_str = "";

            sql_str = "select id, create_time, data from  hk_fbg_real_data_info where ";
            sql_str = sql_str + "dev_id like '%" + dev + "' and sor_code like '%" + sid + "' ";
            sql_str = sql_str + " order by id limit 10000;";


            DataSet ds = null;
           // System.Data.DataRow dr = null;
            try
            {
                ds = db_fbg.ExeQueryToDs(sql_str);
                //dr = ds.Tables[0].Rows[0];
            }
            catch { }

            string r_id="";
            string r_data="";
            string r_rece_time="";


            foreach (System.Data.DataRow dr in ds.Tables[0].Rows)
            {
                r_id = dr["id"].ToString();
                r_data = dr["data"].ToString();
                r_rece_time = dr["create_time"].ToString();
                r_rece_time = r_rece_time.Substring(9, 8);
                // xAxisData.Add(r_rece_time);
                xAxisData.Add(r_id);
                yAxisData.Add(r_data);
            }
  

            if (r_id.Length == 0)
            {
                yAxisData.Add("0");
                xAxisData.Add("0");
            }

            var result = new { Pos= xAxisData, Valu = yAxisData ,Num= zAxisData };
            db_fbg.Close();
            db_fbg.Dispose();
            ds.Reset();
            return Json(result, JsonRequestBehavior.AllowGet);

        }
        
   
    }
}