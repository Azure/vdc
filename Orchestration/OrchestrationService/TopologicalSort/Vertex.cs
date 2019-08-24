using System.Collections.Generic;
using System.Linq;
using System;

namespace VDC.Core.Models
{
    public class GraphModel 
    {
        public string Name { get; set; }
        public bool Enabled { get; set; } = true;
        public List<string> DependsOn { get; set; }
    }
    
    public class Vertex
    {
        public Vertex(string name)
        {
            Name = name;
        }
        public Vertex(string name, bool isVisited)
        {
            this.Name = name;
            this.IsVisited = isVisited;

        }
        public string Name { get; set; }
        public LinkedList<Vertex> Edges { get; set; } = new LinkedList<Vertex>();
        public bool IsVisited { get; set; }
        public Color Color { get; set; }
        public int StartTime { get; set; }
        public int EndTime { get; set; }
        public int EdgeCount
        {
            get
            {
                return Edges.Count;
            }
        }

        public void AddEdge(Vertex to)
        {
            if (!Edges.Any(
                t => t.Name.Equals(
                    to.Name,
                    StringComparison.InvariantCultureIgnoreCase)))
            {
                Edges.AddLast(to);
            }
        }

        public void AddEdges(IEnumerable<Vertex> to)
        {
            var uniqueVertices = 
                Edges.Except(to, new VertexComparer());
            Edges.ToList().AddRange(uniqueVertices);
        }
    }

    class VertexComparer : EqualityComparer<Vertex>
    {
        public override bool Equals(Vertex x, Vertex y)
        {
            return x.Name.Equals(
                y.Name,
                StringComparison.InvariantCultureIgnoreCase);
        }

        public override int GetHashCode(Vertex obj)
        {
            return obj.Name.GetHashCode();
        }
    }

    public enum Color
    {
        None = 0,
        White = 1,
        Gray = 2,
        Black = 3
    }
}