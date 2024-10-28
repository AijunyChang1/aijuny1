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
    public partial class botda_data_detail : System.Web.UI.Page
    {
        static public string constr;
        static public string select_str;
        static public bool Panel_show_table_visable;
        static public bool Panel_chart_visable;
        static public bool Panel_no_record_visible = false;

        protected void Page_Load(object sender, EventArgs e)
        {
            /*
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
            DataList1.DataSource = SqlDataSource1;
            DataList1.DataBind();
            */
            Panel_no_record.Visible = false;
            string page_no = Request.QueryString["page"];
            if (Lable_page.Text.Length == 0)
            {
                Lable_page.Text = "1";
            }
            if (page_no != null)
            {
                page_no = page_no.Trim();
                if (page_no.Length > 0)
                {
                    Lable_page.Text = page_no;
                }
            }
            if (!IsPostBack)
            {
                dlBind(0);
            }
            else 
            {
                dlBind(1);
               
            }
            string rec_no = Request.QueryString["no"];
           

 
            // if ((rec_no != null) &&(show_chart==true))
            if ((rec_no != null)&&((!IsPostBack)))
            {
                if (rec_no.Length > 0)
                {
                    Panel_chart.Visible = true;
                    showChart(rec_no);


                }
            }


        }
        public void showChart(string rec_no)
        {
            rec_no = rec_no.Trim();
            if (rec_no == null) return;
            if (rec_no.Length == 0) return;
            DataBase_Vib botda_db = new DataBase_Vib(2);
            botda_db.Open();
            string cmd_str = "select id, rece_time, data,  begin_pos, dot_len from hk_botda_data where id =" + rec_no;
            OdbcDataReader rd = botda_db.ExecQuerySql(cmd_str);
            string r_id;
            string r_data;
            string r_rece_time;
            string r_begin_pos;
            string r_dot_len;
            if (rd.Read())
            {
                r_id = rd["id"].ToString();
                r_data = rd["data"].ToString();
                r_rece_time = rd["rece_time"].ToString();
                r_begin_pos = rd["begin_pos"].ToString();
                r_dot_len = rd["dot_len"].ToString();
                double fiber_pos = Convert.ToDouble(r_begin_pos);
                double fiber_dot_len = Convert.ToDouble(r_dot_len);


                int data_pos;

                string temp;
                DataTable dt = new DataTable("botda_data");
                dt.Columns.Add(new DataColumn("id", typeof(int)));
                dt.Columns.Add(new DataColumn("rec_time", typeof(string)));
                dt.Columns.Add(new DataColumn("data", typeof(Double)));
                dt.Columns.Add(new DataColumn("position", typeof(string)));
                int t_id = 0;
                string temp_str;
                double local_value_max = 0;
                int id_max = 0;
                double position_max = 0;
                double temp_value = 0;
                while (r_data.Length > 0)
                {
                    data_pos = r_data.IndexOf(",");
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
                  //  temp.
                   // temp_value = Convert.ToDouble(temp);
                    double.TryParse(temp, out temp_value);
                    t_id = t_id + 1;
                    fiber_pos = fiber_pos + fiber_dot_len;

                    if (System.Math.Abs(temp_value) > System.Math.Abs(local_value_max))
                    {
                        local_value_max = temp_value;
                        id_max = t_id;
                        position_max = fiber_pos;
                    }
                    if (t_id % 10 == 0)
                    {
                        DataRow dr = dt.NewRow();
                        dr["id"] = id_max;
                        dr["rec_time"] = r_rece_time;
                        dr["data"] = local_value_max;
                        if (position_max == 0)
                        {
                            position_max = fiber_pos;
                        }
                        temp_str = Convert.ToString(position_max);
                        if (temp_str.Length > 8)
                        {
                            temp_str = temp_str.Substring(0, 8);
                        }

                        dr["position"] = temp_str;
                        dt.Rows.Add(dr);
                        local_value_max = 0;
                        position_max = 0;

                    }

                }
                Label_chart_time.Text= r_rece_time;
                Label_chart_id.Text = r_id;
                Chart1.DataSource = dt;
                Chart1.Series["Series1"].XValueMember = "position";
                Chart1.Series["Series1"].YValueMembers = "data";
                Chart1.Series["Series1"].LegendText = "应变值";
                Chart1.Series["Series1"].IsValueShownAsLabel = false;
                Chart1.DataBind();
                Chart1.Visible = true;

                dt.Dispose();

            }
            rd.Close();
            botda_db.Close();
            botda_db.Dispose();
        }

        public void dlBind(int if_post_back)
        {
            Label_chart_id.Text = "";
            int curpage = Convert.ToInt32(Lable_page.Text);
            PagedDataSource ps = new PagedDataSource();
 
            DataBase_Vib botda_db = new DataBase_Vib(2);
            botda_db.Open();

            if (if_post_back == 0)
            {
                select_str = "select id, rece_time, channel_id, begin_pos, left(dot_len,4) dot_len from hk_botda_data order by id desc limit 5000";
                Label_hide_select_str.Text = select_str;
            }

            select_str = Label_hide_select_str.Text;
            if (select_str==null)
            {
                select_str = "select id, rece_time, channel_id, begin_pos, left(dot_len,4) dot_len from hk_botda_data order by id desc";
            }
            DataSet ds = botda_db.ExeQueryToDs(select_str);
            ps.DataSource = ds.Tables[0].DefaultView;
            ps.AllowPaging = true;
            ps.PageSize = 10;
            ps.CurrentPageIndex = curpage - 1;
            lnkbtnOne.Enabled = true;
            lnkbtnPrev.Enabled = true;
            lnkbtnNext.Enabled = true;
            lnkbtnLast.Enabled = true;
            if (curpage == 1)
            {
                lnkbtnOne.Enabled = false;
                lnkbtnPrev.Enabled = false;
            }
            if (curpage == ps.PageCount)
            {
                lnkbtnNext.Enabled = false;
                lnkbtnLast.Enabled = false;
            }
            Lable_total_page.Text = Convert.ToString(ps.PageCount);
            Repeater1.DataSource = ps;
            // Repeater1.DataKeyField = "id";
            Repeater1.DataBind();
            int row_count = Repeater1.Items.Count;
            if ((Calendar2.Visible == false) && (Calendar1.Visible == false))
            {
                if (row_count > 0)
                {
                    Panel_show_table.Visible = true;
                    Panel_show_table_visable = true;
                    Panel_no_record.Visible = false;
                    Panel_no_record_visible = false;
                }
                else
                {
                    Panel_show_table.Visible = false;
                    Panel_show_table_visable = false;
                    Panel_no_record.Visible = true;
                    Panel_no_record_visible = true;
                    
                }
            }

        }

 
        protected void ImageButton1_click(object sender, EventArgs e)
        {

            if (Calendar1.Visible == false)
            {
                Chart1.Visible = false;
                Panel_show_table.Visible = false;               

                Panel_chart.Visible = false;

                Calendar1.Visible = true;
                Panel_no_record.Visible = false;

            }
            else
            {
                Calendar1.Visible = false;
                if (Panel_show_table_visable == true)
                {
                    Panel_show_table.Visible = true;
                }
                if (Label_chart_id.Text.Length > 0)
                {
                    Panel_chart.Visible = true;
                }
                if (Panel_no_record_visible == true)
                {
                    Panel_no_record.Visible = true;
                }

            }
            Calendar2.Visible = false;

        }

        protected void Calendar1_SelectionChanged(object sender, EventArgs e)
        {
            TextBox1.Text = Calendar1.SelectedDate.Year.ToString() + "-" + Calendar1.SelectedDate.Month.ToString("00") + "-" + Calendar1.SelectedDate.Day.ToString("00");
            Calendar1.Visible = false;
            Calendar2.Visible = false;
            if (Panel_show_table_visable == true)
            {
                Panel_show_table.Visible = true;
            }
            if (Label_chart_id.Text.Length > 0)
            {
                Panel_chart.Visible = true;
            }

            if (Panel_no_record_visible == true)
            {
                Panel_no_record.Visible = true;
            }


        }

        protected void ImageButton2_click(object sender, EventArgs e)
        {
            if (Calendar2.Visible == false)
            {
                Chart1.Visible = false;
                Panel_show_table.Visible = false;

                Panel_chart.Visible = false;
                Calendar2.Visible = true;
                Panel_no_record.Visible = false;

            }
            else
            {
                Calendar2.Visible = false;
                if (Panel_show_table_visable == true)
                {
                    Panel_show_table.Visible = true;
                }
                if (Label_chart_id.Text.Length > 0)
                {
                    Panel_chart.Visible = true;
                }

                if (Panel_no_record_visible == true)
                {
                    Panel_no_record.Visible = true;
                }

            }
            Calendar1.Visible = false;

        }

        protected void Calendar2_SelectionChanged(object sender, EventArgs e)
        {

            TextBox2.Text = Calendar2.SelectedDate.Year.ToString() + "-" + Calendar2.SelectedDate.Month.ToString("00") + "-" + Calendar2.SelectedDate.Day.ToString("00");
            Calendar1.Visible = false;
            Calendar2.Visible = false;
            if (Panel_show_table_visable == true)
            {
                Panel_show_table.Visible = true;
            }
            if (Label_chart_id.Text.Length > 0)
            {
                Panel_chart.Visible = true;
            }
            if (Panel_no_record_visible == true)
            {
                Panel_no_record.Visible = true;
            }

        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            Chart1.Visible = false;
            Panel_show_table_visable = false;
            Panel_chart_visable = false;
            Panel_show_table.Visible = false;
            Panel_chart.Visible = false;
            Label_chart_id.Text = "";
            Lable_page.Text = "1";
            Calendar2.Visible = false;
            Calendar1.Visible = false;
            string start_date = TextBox1.Text;
            string end_date = TextBox2.Text;
            string id_no = TextBox_no.Text;
            select_str = "select id, rece_time, channel_id, begin_pos, left(dot_len,4) dot_len from hk_botda_data  where 1=1 ";
            if (start_date.Length > 1)
            {
                start_date = start_date + " 00:00:00";
                select_str = select_str + "and rece_time > '" + start_date + "'";
            }
            if (end_date.Length > 1)
            {
                end_date = end_date + " 23:59:59";
                select_str = select_str + " and rece_time < '" + end_date + "'";
            }
            if (DropDownList1.SelectedValue != "0")
            {
                select_str = select_str + " and channel_id=" + DropDownList1.SelectedValue;
            }
            if (id_no.Length > 0)
            {
                select_str = select_str + " and id=" + id_no;


            }
            Label_hide_select_str.Text = select_str;
            dlBind(1);
  
        }

        protected void lnkbtnOne_Click(object sender, EventArgs e)
        {
            Lable_page.Text = "1";
            dlBind(1);
            Panel_chart.Visible = false;
        }

        protected void lnkbtnPrev_Click(object sender, EventArgs e)
        {
            Lable_page.Text = Convert.ToString(Convert.ToInt32(Lable_page.Text)-1);
            dlBind(1);
            Panel_chart.Visible = false;
        }
        protected void lnkbtnNext_Click(object sender, EventArgs e)
        {
            Lable_page.Text = Convert.ToString(Convert.ToInt32(Lable_page.Text) + 1);
            dlBind(1);
            Panel_chart.Visible= false;
        }
        protected void lnkbtnLast_Click(object sender, EventArgs e)
        {
            Lable_page.Text = this.Lable_total_page.Text;
            dlBind(1);
            Panel_chart.Visible = false;
        }

    }
}