using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using WpfGrowersApp.Models;

namespace WpfGrowersApp.Services
{
    public class DataService
    {
        private readonly GrowersDbContext _context;

        public DataService(GrowersDbContext context)
        {
            _context = context;
        }

        public List<Grower> GetAllGrowers()
        {
            return _context.Growers.ToList();
        }

        public Grower GetGrowerById(int id)
        {
            return _context.Growers.Find(id);
        }

        public void AddGrower(Grower grower)
        {
            _context.Growers.Add(grower);
            _context.SaveChanges();
        }

        public void UpdateGrower(Grower grower)
        {
            _context.Growers.Update(grower);
            _context.SaveChanges();
        }

        public void DeleteGrower(int id)
        {
            var grower = _context.Growers.Find(id);
            if (grower != null)
            {
                _context.Growers.Remove(grower);
                _context.SaveChanges();
            }
        }
    }
}