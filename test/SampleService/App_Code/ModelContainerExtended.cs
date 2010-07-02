using System;
using System.Data;
using System.Data.Objects;
using System.Linq;

namespace Model
{
    /// <summary>
    /// Extensions to the default container
    /// </summary>
    public partial class ModelContainer
    {
        partial void OnContextCreated()
        {
            SavingChanges += ContainerSavingChanges;
        }

        private static void ContainerSavingChanges(object sender, EventArgs e)
        {
            var updatedEntites = ((ObjectContext) sender).ObjectStateManager.GetObjectStateEntries(EntityState.Modified);
            foreach (var ose in updatedEntites)
            {
                var type = ose.Entity.GetType();
                if (type.GetProperties().Any(p => typeof(AuditFields).IsAssignableFrom(p.PropertyType)))
                {
                    dynamic entity = ose.Entity;
                    entity.AuditFields.ModifiedDate = DateTime.UtcNow;
                }
            }
        }
    }
}