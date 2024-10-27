using System;
using System.Web;

namespace MvcGuestbook.Models
{
    public class AddUser
    {
        public string username { get; set; }
        public string passwd { get; set; }
        public int usertype { get; set; }

    }

}
