using System.Data.Services;
using System.Data.Services.Common;
using System.Linq;
using System.ServiceModel;
using System.ServiceModel.Web;
using RubyODataService.Models;

namespace RubyODataService
{
    [ServiceBehavior(IncludeExceptionDetailInFaults = true)]
    public class RubyOData : DataService<RubyODataContext>
    {
        // This method is called only once to initialize service-wide policies.
        public static void InitializeService(DataServiceConfiguration config)
        {
            config.SetEntitySetAccessRule("*", EntitySetRights.All);
            config.SetServiceOperationAccessRule("*", ServiceOperationRights.All);
            config.DataServiceBehavior.MaxProtocolVersion = DataServiceProtocolVersion.V3;
            config.UseVerboseErrors = true;
        }

        /// <summary>
        /// Cleans the database for testing.
        /// </summary>
        [WebInvoke]
        public void CleanDatabaseForTesting()
        {
            CurrentDataSource.Database.Delete();
            CurrentDataSource.Database.CreateIfNotExists();
        }

        [WebGet]
        public IQueryable<Category> EntityCategoryWebGet()
        {
            return CurrentDataSource.Categories;
        }
        [WebGet]
        public Category EntitySingleCategoryWebGet(int id)
        {
            return CurrentDataSource.Categories.FirstOrDefault(c => c.Id == id);
        }
    }
}
