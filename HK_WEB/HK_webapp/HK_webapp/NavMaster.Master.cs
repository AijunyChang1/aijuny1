using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Security;
using System.Security.Principal;

namespace HK_webapp
{
    public partial class NavMaster : System.Web.UI.MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            
            string username;
            username = Context.User.Identity.Name;

            
            string role = Request.QueryString["userrole"];
            
            if (role == "0")
            {
                 CreateUserLink.Visible = true;
                 Session["role"] = 0;
            }
            else if (role == "1")
            {
                CreateUserLink.Visible = false;
                Session["role"] = null;
            }
            else if (Session["role"] != null)
            {
                CreateUserLink.Visible = true;
            }
            else
            {
                CreateUserLink.Visible = false;
            }

                         

        }

        protected void On_Logout_Click(object sender, EventArgs e)
        {
            FormsAuthentication.SignOut();
            Response.Redirect("login.aspx");
        }
    }
}