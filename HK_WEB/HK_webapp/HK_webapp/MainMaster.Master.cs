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
    public partial class MainMaster : System.Web.UI.MasterPage
    {
        public DateTime LoginTime = DateTime.Now;
        protected void Page_Load(object sender, EventArgs e)
        {
            //LoginTime = DateTime.Now;
            string username;            
            username = Context.User.Identity.Name;
            if (username.Length > 1)
            {
                UserLabel.Text = username;
                UserLabel.Visible = true;
            }
            else
            {
                UserLabel.Visible = false;
            }
            TimeLabel.DataBind();
        }
    }
}