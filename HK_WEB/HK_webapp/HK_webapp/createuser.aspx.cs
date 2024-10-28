using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data.Odbc;
using System.Web.Security;

namespace HK_webapp
{
    public partial class createuser : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }
        protected void Create_User_Button_Click(object sender, EventArgs e)
        {
            Label1.Visible = false;
            string user_name = UserNameBox.Text;
            user_name=user_name.Trim();
            if (user_name.Length < 2)
            {
                Label1.Text = "用户名必须大于两个字符！";
                Label1.ForeColor = System.Drawing.Color.Red;
                Label1.Visible = true;
                return;
            }

            if ((RadioButtonList1.SelectedValue != "0")&&(RadioButtonList1.SelectedValue != "1"))
            {
                Label1.Text = "请选择用户类型！";
                Label1.ForeColor = System.Drawing.Color.Red;
                Label1.Visible = true;
                return;            
            }
            if (PasswordBox.Text != RePasswordBox.Text)
            {
                Label1.Text = "密码不一致！";
                Label1.ForeColor = System.Drawing.Color.Red;
                Label1.Visible = true;
                return;             
            
            }
            string is_admin = "";
            if (int.Parse(RadioButtonList1.SelectedValue) == 0)
            {
                is_admin = "0";
            }
            else
            {
                is_admin = "1";
            }
            string pw_hash = FormsAuthentication.HashPasswordForStoringInConfigFile(PasswordBox.Text, "SHA1");
            Label1.ForeColor = System.Drawing.Color.Green;
            Label1.Visible = false;

            string db_ip = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_IP"];
            string db_dsn = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_USER_DSN"];
            string db_user = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_USER"];
            string db_password = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_PW"];
            string db_name = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_USER_NAME"];
            DateTime LoginTime = DateTime.Now;
            string login_time = LoginTime.ToString();

            string constr = "dsn=" + db_dsn + ";server=" + db_ip + ";uid=" + db_user + ";database=" + db_name + ";port=3306;pwd=" + db_password;
            
            OdbcConnection con = new OdbcConnection(constr);
            con.Open();
            string query_str = "select * from hk_user_info where user_name='" + user_name + "'";
            OdbcCommand query_com = new OdbcCommand(query_str, con);
            OdbcDataReader my_read = query_com.ExecuteReader();
            if (my_read.Read())
            {
                Label1.Text = "此用户已存在，请换一个用户名！";
                Label1.ForeColor = System.Drawing.Color.Red;
                Label1.Visible = true;
                return;   
            
            }

            string cmd_str = "insert into hk_user_info(user_name, pass_word, user_role, create_time, is_active) values (";
            cmd_str = cmd_str + "'"+ user_name + "','" + pw_hash + "'," + is_admin +",'"+ login_time + "', 1)" ;            
           //OdbcDataAdapter oda = new OdbcDataAdapter(cmd_str, con);
            OdbcCommand com = new OdbcCommand(cmd_str, con);
            com.ExecuteNonQuery();
            com.Dispose();
            con.Close();
            con.Dispose();
            
            string suc_text = "添加新用户:" + user_name + "成功！";
            Label1.Text = suc_text;
            Label1.ForeColor = System.Drawing.Color.Green;
            Label1.Visible = true;



           // oda.Update();


        
        }
    }
}