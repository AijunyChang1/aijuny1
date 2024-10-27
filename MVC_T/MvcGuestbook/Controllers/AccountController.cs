using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Security;
using System.Security.Principal;
using MvcGuestbook.Models;

using System.Data;
using System.Collections;

namespace MvcGuestbook.Controllers
{
    public class AccountController : Controller
    {
        // GET: Account
        public ActionResult Index()
        {
            return View();
        }

        public ActionResult newaccount()
        {
            ViewBag.Username = HttpContext.User.Identity.Name;
            ViewBag.Displaynewbn = true;
            
            if (Request.Cookies["userrole"] != null)
            {
                ViewBag.Userrole = Request.Cookies["userrole"];
            }
            return View();
        }

        public ActionResult saveuser(AddUser newuser)
        {
            ViewBag.Username = HttpContext.User.Identity.Name;
            ViewBag.Displaynewbn = true;
            string pw_hash = FormsAuthentication.HashPasswordForStoringInConfigFile(newuser.passwd, "SHA1");
            

            if (Request.Cookies["userrole"] != null)
            {
                ViewBag.Userrole = Request.Cookies["userrole"];
            }
            DateTime LoginTime = DateTime.Now;
            string login_time = LoginTime.ToString();
            DataBase_Vib db_user = new DataBase_Vib(4);
            db_user.Open();
            string q_str = "select count(id) c from hk_user_info where user_name='";
            q_str = q_str + newuser.username + "';";
            DataSet ds = db_user.ExeQueryToDs(q_str);
            string ex = "0";
            if (ds != null)
            {
                ex = ds.Tables[0].Rows[0]["c"].ToString();
                
            }
            else
            {
                ex = "0";
            }

            if (ex == "0")
            {
                string cmd_str = "insert into hk_user_info(user_name, pass_word, user_role, create_time, is_active) values (";
                cmd_str = cmd_str + "'" + newuser.username + "','" + pw_hash + "'," + newuser.usertype + ",'" + login_time + "', 1)";
                db_user.ExeNoQuery(cmd_str);
                
                ViewBag.Count = "0";
            }
            else 
            {
                ViewBag.Count = ex;
            }
            ViewBag.newusername = newuser.username;

            db_user.Close();
            db_user.Dispose();
            
            ds.Reset();
            return View();
        }

        public ActionResult logout()
        {
            FormsAuthentication.SignOut();
            // Response.Redirect("login.aspx");

            //return View();
            //return RedirectToAction("Index");
            //return new EmptyResult(); or return;
            //return PartialView(); //不带模板
            //return View("Index", "模板");
            //return Content("<ROOT><TEXT>123</TEXT></ROOT>", "text/xml", System.Text.Encoding.UTF8);
            //return Content(strHTML);//返回html字符串。strHTML为变量 可以写成：
            //return strHTML;

            return Redirect("login.aspx");
        }
    }
}