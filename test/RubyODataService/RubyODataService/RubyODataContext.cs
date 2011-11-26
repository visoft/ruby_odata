using System.Data.Entity;
using RubyODataService.Models;

namespace RubyODataService
{
    public class RubyODataContext : DbContext
    {
        public RubyODataContext()
        {
            // Disable proxy creation, which doesn’t work well with data services. 
            this.Configuration.ProxyCreationEnabled = false;
        }
        public DbSet<Product> Products { get; set; }
        public DbSet<Category> Categories { get; set; }
    }
}