using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Security;
using System.Data.Odbc;



namespace MvcGuestbook
{
    public partial class login : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            Label1.Visible = false;
            
         
        }
        protected void Button1_Click(object sender, EventArgs e)
        {
            Page.RegisterStartupScript("111", "<script>document.documentElement.requestFullscreen();</script>");
            if ((UserNameBox.Text == "hkadmin") && (PasswordBox.Text == "123456"))
            {
                Label1.Text = "欢迎你，登录成功！";
                Label1.ForeColor = System.Drawing.Color.Green;
                Label1.Visible = true;
                FormsAuthentication.SetAuthCookie(UserNameBox.Text, false);
                Response.Redirect("/Home/Index?userrole=0");
            }
            else if ((UserNameBox.Text == "admin") && (PasswordBox.Text == "123456"))
            {
                Label1.Text = "欢迎你，登录成功！";
                Label1.ForeColor = System.Drawing.Color.Green;
                Label1.Visible = true;
                FormsAuthentication.SetAuthCookie(UserNameBox.Text, false);
                Response.Redirect("/Home/Index?userrole=1");
            }
            else 
            {
                string usr_name = UserNameBox.Text;
                string pw_hash = FormsAuthentication.HashPasswordForStoringInConfigFile(PasswordBox.Text, "SHA1");
                if (usr_name.Length == 0)
                {
                   this.Response.Write("<script language='javascript'> alert('请输入用户名！');</script>");
                   return;

                }
                string db_ip = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_IP"];
                string db_dsn = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_USER_DSN"];
                string db_user = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_USER"];
                string db_password = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_PW"];
                string db_name = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_USER_NAME"];

                string constr = "dsn=" + db_dsn + ";server=" + db_ip + ";uid=" + db_user + ";database=" + db_name + ";port=3306;pwd=" + db_password;

                OdbcConnection con = new OdbcConnection(constr);

                string cmd_str = "select pass_word, user_role from  hk_user_info where user_name='" + usr_name+"'";
                con.Open();
                OdbcCommand com = new OdbcCommand(cmd_str, con);
                OdbcDataReader rd = com.ExecuteReader();

                if (rd.Read())
                {
                    if (pw_hash == rd["pass_word"].ToString())
                    {
                        FormsAuthentication.SetAuthCookie(UserNameBox.Text, false);
                        
                        Label1.Text = "欢迎你，登录成功！";
                        Label1.ForeColor = System.Drawing.Color.Green;
                        Label1.Visible = true;
                        if (rd["user_role"].ToString() == "0")
                        {
                            con.Close();
                            Response.Redirect("/Home?userrole=0");
                        }
                        else 
                        {
                            con.Close();
                            Response.Redirect("/Home?userrole=1");
                        }

                        return;
                    }
                
                }

                com.Dispose();
                con.Close();
                con.Dispose();
               


                Label1.Text = "您输入的用户名或密码有误！";
                Label1.ForeColor = System.Drawing.Color.Red;
                Label1.Visible = true;
            }
        }

    }
}