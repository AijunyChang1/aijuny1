using System;
using System.Data;
using System.Configuration;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Data.Odbc;


namespace MvcGuestbook
{
    public class DataBase_Vib:IDisposable
    {
        private OdbcConnection con;
        private string constr;
        private int db_type;          // 1-vib, 2-botda, 3-dts, 4-user, 5-fbg
        public DataBase_Vib(int u_type)
        {
            con = null;
            db_type = u_type;
        }
        public void Dispose()
        {
            if (con != null)
            {
                con.Dispose();
                constr = "";
                con = null;
            }
        }
        public void Close()
        {
            if (con != null)
            {
                con.Close();
            }
        }

        public void Open()
        {
            string db_ip = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_IP"];
            string db_dsn;
            if (db_type == 1)
            {
                db_dsn = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_VIB_DSN"];
            }
            else if (db_type == 2)
            {
                db_dsn = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_BOTDA_DSN"];
            }
            else if (db_type == 3)
            {
                db_dsn = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_DTS_DSN"];
            }
            else if (db_type == 5)
            {
                db_dsn = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_FBG_DSN"];
            }
            else
            {
                db_dsn = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_USER_DSN"];
            }
            string db_user = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_USER"];
            string db_password = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_PW"];
            string db_name;
            if (db_type == 1)
            {
                db_name = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_VIB_NAME"];
            }
            else if (db_type == 2)
            {
                db_name = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_BOTDA_NAME"];
            }
            else if (db_type == 3)
            {
                db_name = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_DTS_NAME"];
            }
            else if (db_type == 5)
            {
                db_name = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_FBG_NAME"];
            }
            else
            {
                db_name = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_USER_NAME"];
            }
            constr = "dsn=" + db_dsn + ";server=" + db_ip + ";uid=" + db_user + ";database=" + db_name + ";port=3306;pwd=" + db_password;
            if (con == null)
            {
                con = new OdbcConnection(constr);
            }
            con.Open();
        }

        public OdbcDataReader ExecQuerySql(string sql_str)
        {
            sql_str = sql_str.Trim();
            if (sql_str.Length == 0)
            {
                return null;
            }
            OdbcCommand com = new OdbcCommand(sql_str, con);
            OdbcDataReader rd = com.ExecuteReader();
            com.Dispose();
            return rd;
        }

        public DataSet ExeQueryToDs(string sql_str)
        {
            sql_str = sql_str.Trim();
            if (sql_str.Length == 0)
            {
                return null;
            }
            OdbcCommand com = new OdbcCommand(sql_str, con);
            OdbcDataAdapter vib_adapter = new OdbcDataAdapter();
            vib_adapter.SelectCommand = com;
            DataSet vib_ds = new DataSet();
            vib_adapter.Fill(vib_ds);
            com.Dispose();
            return vib_ds;
        }

        public void ExeNoQuery(string sql_str)
        {
            sql_str = sql_str.Trim();
            if (sql_str.Length == 0)
            {
                return;
            }
            OdbcCommand com = new OdbcCommand(sql_str, con);
            com.ExecuteNonQuery();
            com.Dispose();

        }



    }
}