/*
 * This class contains only 'inner' clones
 */
public class extension {
	//ctor
	public extension()
	{
	}
	
	public String extend(String source, int value)
	{
		String result = source;
		for(int i=0; i < value; i++)
		{
			result += source;
		}
		return result;
	}
	
	public int extend (int source, int value)
	{
		int result = source;
		
		for(int i=0; i < value; i++)
		{
			result += source;
		}
		
		return result;
	}
	
	public String implode(String source, int value)
	{
		String result = source;
		for(int i=0; i < value; i++)
		{
			result += source;
		}	
		return result;
	}
}