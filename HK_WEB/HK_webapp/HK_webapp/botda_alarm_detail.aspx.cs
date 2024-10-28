using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data.Odbc;
using System.Data;

namespace HK_webapp
{
    public partial class botda_alarm_detail : System.Web.UI.Page
    {
        static public string constr;
        static public string select_str;
        static public bool panel2_visable;
        static public bool panel3_visable;
        protected void Page_Load(object sender, EventArgs e)
        {
            string db_ip = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_IP"];
            string db_dsn = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_BOTDA_DSN"];
            string db_user = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_USER"];
            string db_password = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_PW"];
            string db_name = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_BOTDA_NAME"];

            constr = "dsn=" + db_dsn + ";server=" + db_ip + ";uid=" + db_user + ";database=" + db_name + ";port=3306;pwd=" + db_password;
            SqlDataSource1.ConnectionString = constr;
            if (!IsPostBack)
            {
                select_str = "SELECT  id, channel_id, device_name, alarm_time,update_time,event_type,alarm_guid, left(max_value,8) max_value,limen_value, " +
                    "case alarm_format when 1 then '定值报警' when 2 then '区域值差' when 3 then '差值报警' when  4 then '故障' when 5 then" +
                    "'故障恢复' else '未知报警' end alarm_type, left(begin_pos,8) begin_pos, left(end_pos,8) end_pos, left(cent_pos,8) cent_pos, case is_show when 0 then '未确认' when 1 then '已确认' else '误报' end" +
                    " show_check FROM  hk_botda_alarm_info order by id desc limit 5000";
            }

            SqlDataSource1.SelectCommand = select_str;

        }

        protected void ImageButton1_click(object sender, EventArgs e)
        {
            if (Calendar1.Visible == false)
            {
                Calendar1.Visible = true;
                GridView1.Visible = false;
                Panel2.Visible = false;
                Panel3.Visible = false;

            }
            else
            {
                Calendar1.Visible = false;
                GridView1.Visible = true;
                if (panel2_visable == true)
                {
                    Panel2.Visible = true;
                }
                if (panel3_visable == true)
                {
                    Panel3.Visible = true;
                }
            }
            Calendar2.Visible = false;

        }
        protected void Calendar1_SelectionChanged(object sender, EventArgs e)
        {
            TextBox1.Text = Calendar1.SelectedDate.Year.ToString() + "-" + Calendar1.SelectedDate.Month.ToString("00") + "-" + Calendar1.SelectedDate.Day.ToString("00");
            Calendar1.Visible = false;
            Calendar2.Visible = false;
            GridView1.Visible = true;
            if (panel2_visable == true)
            {
                Panel2.Visible = true;
            }
            if (panel3_visable == true)
            {
                Panel3.Visible = true;
            }

        }
        protected void ImageButton2_click(object sender, EventArgs e)
        {

            if (Calendar2.Visible == false)
            {
                Calendar2.Visible = true;
                GridView1.Visible = false;
                Panel2.Visible = false;
                Panel3.Visible = false;
            }
            else
            {
                Calendar2.Visible = false;
                GridView1.Visible = true;
                if (panel2_visable == true)
                {
                    Panel2.Visible = true;
                }
                if (panel3_visable == true)
                {
                    Panel3.Visible = true;
                }
            }
            Calendar1.Visible = false;

        }
        protected void Calendar2_SelectionChanged(object sender, EventArgs e)
        {
            TextBox2.Text = Calendar2.SelectedDate.Year.ToString() + "-" + Calendar2.SelectedDate.Month.ToString("00") + "-" + Calendar2.SelectedDate.Day.ToString("00");
            Calendar2.Visible = false;
            Calendar1.Visible = false;
            GridView1.Visible = true;
            if (panel2_visable == true)
            {
                Panel2.Visible = true;
            }
            if (panel3_visable == true)
            {
                Panel3.Visible = true;
            }

        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            panel2_visable = false;
            panel3_visable = false;
            Panel2.Visible = false;
            Panel3.Visible = false;
            Calendar2.Visible = false;
            Calendar1.Visible = false;
            string start_date = TextBox1.Text;
            string end_date = TextBox2.Text;
            select_str = "SELECT  id, channel_id, device_name, alarm_time,update_time,event_type,alarm_guid, left(max_value,8) max_value,limen_value, " +
                    "case alarm_format when 1 then '定值报警' when 2 then '区域值差' when 3 then '差值报警' when  4 then '故障' when 5 then" +
                    "'故障恢复' else '未知报警' end alarm_type, left(begin_pos,8) begin_pos, left(end_pos,8) end_pos, left(cent_pos,8) cent_pos, case is_show when 0 then '未确认' when 1 then '已确认' else '误报' end" +
                    " show_check FROM  hk_botda_alarm_info  where 1=1 ";
            if (start_date.Length > 1)
            {
                start_date = start_date + " 00:00:00";
                select_str = select_str + "and alarm_time > '" + start_date + "'";
            }
            if (end_date.Length > 1)
            {
                end_date = end_date + " 23:59:59";
                select_str = select_str + " and alarm_time < '" + end_date + "'";
            }

            if (DropDownList1.SelectedValue != "0")
            {
                select_str = select_str + " and channel_id=" + DropDownList1.SelectedValue;
            }
            if (DropDownList2.SelectedValue != "0")
            {
                select_str = select_str + " and alarm_format=" + DropDownList2.SelectedValue;
            }

            if (DropDownConfirm.SelectedValue != "0")
            {
                if (DropDownConfirm.SelectedValue == "1")
                {
                    select_str = select_str + " and is_show=1";
                }
                if (DropDownConfirm.SelectedValue == "2")
                {
                    select_str = select_str + " and is_show=0";
                }
                if (DropDownConfirm.SelectedValue == "3")
                {
                    select_str = select_str + " and is_show=2";
                }
            }

            select_str = select_str + " order by id desc";

            SqlDataSource1.SelectCommand = select_str;


            GridView1.Visible = true;
            GridView1.DataBind();
            int row_count = GridView1.Rows.Count;

            if (row_count == 0)
            {
                Panel2.Visible = true;
                panel2_visable = true;
                panel3_visable = false;
            }
            else
            {
                panel2_visable = false;
                panel3_visable = true;
                OdbcConnection con = new OdbcConnection(constr);
                con.Open();
                OdbcDataAdapter botda_adapter = new OdbcDataAdapter();
                OdbcCommand botda_command = new OdbcCommand(select_str, con);
                botda_adapter.SelectCommand = botda_command;
                DataSet botda_ds = new DataSet();
                botda_adapter.Fill(botda_ds);
                DataTable botda_dt = botda_ds.Tables[0];

                Label2.Text = "共查到" + botda_dt.Rows.Count.ToString().Trim() + "条记录！";

                // Label2.Text = "共查到" + row_count.ToString() + "条记录！";
                Panel3.Visible = true;
                con.Close();
            }
        }



    }
}