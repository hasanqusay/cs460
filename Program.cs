using System;
using System.Linq;
using System.Windows.Forms;
using System.Collections.Generic;

namespace facialrecon {
    static class Program {
        [STAThread]
        static void Main() {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new FrmPrincipal());
                        }
    }
}
