using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Data.Odbc;
using System.Data;

namespace MvcGuestbook.Controllers
{
    public class CabController : Controller
    {
        // GET: Cab
        static string cabn { get; set; }

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
        public ActionResult Cabadmin()
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


        ///////////////////////////////////////////////////////////
        public ActionResult Clearev()
        {

            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            string sql_str = "";

            sql_str = "update  hk_show_figure_event set is_show=1";
            db_vib.ExeNoQuery(sql_str);

            db_vib.Close();
            db_vib.Dispose();

            return new EmptyResult();
        }

        public ActionResult Restoreev()
        {

            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            string sql_str = "";
            sql_str = "select id from hk_show_figure_event order by id desc limit 1";
            DataSet ds = db_vib.ExeQueryToDs(sql_str);
            string lastid = "";
            lastid = ds.Tables[0].Rows[0]["id"].ToString();
            ds.Dispose();
            int nlastid = Convert.ToInt32(lastid);
            nlastid = nlastid - 10;
            lastid=nlastid.ToString();
            sql_str = "update  hk_show_figure_event set is_show=0 where id > " + lastid ;
            db_vib.ExeNoQuery(sql_str);
            nlastid = nlastid - 90;
            lastid = nlastid.ToString();
            sql_str = "delete from hk_show_figure_event where id < " + lastid;
            //  db_vib.ExeNoQuery(sql_str);
            db_vib.Close();
            db_vib.Dispose();


            return new EmptyResult();
        }

        public ActionResult Cablist()
        {
            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            DataSet ds = db_vib.ExeQueryToDs("select count(*) c from hk_cable_figure_id T;");
            if (ds != null)
            {
                ViewBag.Vibcount = ds.Tables[0].Rows[0]["c"].ToString();
                cabn = ds.Tables[0].Rows[0]["c"].ToString();
            }
            ds.Reset();
            ds = db_vib.ExeQueryToDs("select id, create_date, channel, cable_type, cable_producer, cable_len, cable_d, cable_material, cable_annotation from hk_cable_figure_id order by id desc limit 10;");
            ViewData["ds"] = ds;
            ds.Dispose();

            db_vib.Close();
            db_vib.Dispose();
            return PartialView();
        }

        public ActionResult Cardshow()
        {
            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            DataSet ds;
            // DataSet ds = db_vib.ExeQueryToDs("select count(*) c from hk_fiber_event_detail;");
            // if (ds != null)
            // {
            //    ViewBag.Vibcount = ds.Tables[0].Rows[0]["c"].ToString();
            // }
            // ds.Reset();
            /*
             string sql = "SELECT hk_show_figure_event.id,hk_show_figure_event.channel, hk_show_figure_event.push_time, hk_cable_figure_id.cable_type," +
                  "hk_cable_figure_id.cable_producer,hk_cable_figure_id.cable_produce_date, hk_cable_figure_id.cable_len, hk_cable_figure_id.cable_d,case hk_cable_figure_id.cable_material when 1 then '铜芯' " +
                  "when 2 then '铝芯' when 3 then '铜铝芯' end cable_material, hk_cable_figure_id.cable_annotation FROM hk_show_figure_event, hk_cable_figure_id where " +
                  "hk_show_figure_event.channel = hk_cable_figure_id.channel and hk_show_figure_event.is_show = 0 order by id desc limit 4;";
            */
            string sql = "SELECT a.id,a.channel, a.push_time, b.cable_type,b.cable_producer,b.cable_produce_date, b.cable_len, b.cable_d,case b.cable_material when 1 then '铜芯' " +
                 "when 2 then '铝芯' when 3 then '铜铝芯' end cable_material, b.cable_annotation FROM hk_show_figure_event a  left join hk_cable_figure_id b on a.channel = b.channel where " +
                  "a.is_show = 0 order by id desc limit 4;"; 
             ds = db_vib.ExeQueryToDs(sql);
            //ds = query_ds;
            ViewData["ds"] = ds;

          //  ds.Reset();

            db_vib.Close();
            db_vib.Dispose();
            return PartialView();
        }

        public ActionResult Create()
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
            return PartialView();
        }

        public ActionResult Savecab(FormCollection collection)
        {
            /*
            string cabtype = collection["type"];
            string cabproducer = collection["producer"];
            string prodate = collection["prodate"];
            string cablen = collection["cablen"];
            string cabdi = collection["cabdi"];
            string chid = collection["channelid"];
            string cabmat = collection["cabmat"];
            */
            string cabtype = Request.QueryString["type"];
            string cabproducer = Request.QueryString["producer"];
            string prodate = Request.QueryString["prodate"];
            string cablen = Request.QueryString["cablen"];
            string cabdi = Request.QueryString["cabdi"];
            string chid = Request.QueryString["channelid"];
            string cabmat = Request.QueryString["cabmat"];

            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();

            DateTime LoginTime = DateTime.Now;
            string login_time = LoginTime.ToString();
            string sql= "insert into hk_cable_figure_id(channel, cable_type, cable_producer, cable_produce_date, " +
                "cable_len, cable_d, cable_material, create_date) values("+ chid+ ", '"+cabtype+"','"+ cabproducer+"','"+prodate+"',"
                + cablen+",'"+cabdi+"','"+cabmat+"','"+login_time+"'); ";
            db_vib.ExeNoQuery(sql);

            db_vib.Close();
            db_vib.Dispose();
    
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
            return View("Cabadmin");
            //return new EmptyResult();
        }

        public ActionResult Delcabdb(FormCollection collection)
        {
            string id = Request.QueryString["id"];
            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            string sql = "delete from hk_cable_figure_id"  + " where id=" + id;

            db_vib.ExeNoQuery(sql);

            db_vib.Close();
            db_vib.Dispose();

            return new EmptyResult();

        }

        public ActionResult Edit()
        {
            string id = Request.QueryString["id"];
            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            DataSet ds = db_vib.ExeQueryToDs("select id, create_date, channel, cable_type, cable_producer,cable_produce_date, cable_len, cable_d, cable_material, cable_annotation from hk_cable_figure_id where id=" + id);
            if (ds != null)
            {
                ViewData["ds"] = ds;
            }

            ds.Dispose();

            db_vib.Close();
            db_vib.Dispose();
            return PartialView();
        }
        public ActionResult Editcabdb(FormCollection collection)
        {


           // string cabtype = collection["type"];
           // string cabproducer = collection["producer"];
           //string prodate = collection["prodate"];
           // string cablen = collection["cablen"];
           // string cabdi = collection["cabdi"];
          //  string chid = collection["channelid"];
          //  string cabmat = collection["cabmat"];
            string id = Request.QueryString["id"];


            string cabtype = Request.QueryString["type"];
            string cabproducer = Request.QueryString["producer"];
            string prodate = Request.QueryString["prodate"];
            string cablen = Request.QueryString["cablen"];
            string cabdi = Request.QueryString["cabdi"];
            string chid = Request.QueryString["channelid"];
            string cabmat = Request.QueryString["cabmat"];
            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();

            DateTime LoginTime = DateTime.Now;
            string login_time = LoginTime.ToString();

            string sql = "update hk_cable_figure_id set channel=" + chid + ", cable_type='" + cabtype + "',cable_producer='" + cabproducer +
                "',cable_produce_date='" + prodate + " ',cable_len=" + cablen + ",cable_d='" + cabdi + "',cable_material=" + cabmat + " where id=" + id;

            db_vib.ExeNoQuery(sql);

            db_vib.Close();
            db_vib.Dispose();

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
            return View("Cabadmin");

        }
        [HttpPost]
        public ActionResult UploadFile(FormCollection collection)
        {
            string msg = string.Empty;
            string chid = collection["channelid"];
            if (Request.Files.Count > 0)
            {
                HttpPostedFileBase file = Request.Files["file1"];
                if (file.ContentLength < 5 * 1024 * 1024)
                {
                    string fileType = System.IO.Path.GetExtension(file.FileName);//获取文件类型
                    if (!System.IO.Directory.Exists(Server.MapPath("~/Pictures/")))
                    {
                        System.IO.Directory.CreateDirectory(Server.MapPath("~/Pictures/"));
                    }
                    string filePath = Server.MapPath("~/Pictures/");//保存文件的路径
                    if (fileType != null)
                    {
                        fileType = fileType.ToLower();//将文件类型转化成小写
                        if ("(.gif)|(.jpg)|(.bmp)|(.jpeg)|(.png)".Contains(fileType))
                        {
                            string newFileName="ch"+chid+ fileType;
                            file.SaveAs(filePath + newFileName);
                            string str = "/Pictures/" + newFileName;
                            msg = str;
                        }
                        else
                        {
                            msg = "只支持图片格式";
                        }
                    }
                }
                else
                {
                    msg = "图片大小不能超过5M";
                }
            }
            else
            {
                msg = "上传图片不能为空";
            }
            return Content(msg);
        }

    }
}