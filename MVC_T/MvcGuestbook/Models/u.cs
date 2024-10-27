using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MvcGuestbook.Models
{
    public class u
    {
        [DisplayName("序号")]
        public int id { get; set; }

        [Required]
        [DisplayName("用户名")]
        public string user_name { get; set; }

        [Required]
        [DisplayName("密码")]
        public string pass_word { get; set; }

        [Required]
        [DisplayName("账号类型")]
        public Nullable<int> user_role { get; set; }

        [DisplayName("创建时间")]
        public string create_time { get; set; }

        [DisplayName("最近登陆时间")]
        public string last_login_time { get; set; }

        [DisplayName("是否激活")]
        public Nullable<bool> is_active { get; set; }

        [NotMapped]
        public string test {
            get {
                return this.user_name.Substring(0, 1);
            }

            set {
                this.user_name = value;
            }
        }
    }
}