/*
 * This class contains a large and small clone (small inner/outer clone, large outer clone)
 */
public class utils
{	
	//same name
	public void DupSource()
	{
		String test = "";
		String test1 = "1";
		String test2 = "2";
		String test3 = "3";
		if(test2 == "")
		{
			test3 = "1+1";
		}
		for(int i = 0; i < 10; i++)
		{
			test = "lala";
		}
	}
	
	private void HelloWorld()
	{
		String test = "helloworld";
	}
	
	public void SmallOuterDuplicate()
	{
		String s1 = "s1";
		String test1 = "1";
		String test2 = "2";
		String test3 = "3";
		if(test2 == "")
		{
			test3 = "1+1";
		}
		String e1 = "s2";
	}
	
	/*
	public void SmallOuterDuplicate2()
	{
		String anders = "anders";
		String test2 = "2";
		String test3 = "3";
		String test = "";
		String test1 = "1";
		if(test2 == "")
		{
			test3 = "1+1";
		}
		for(int i = 0; i < 10; i++)
		{
			test = "lala";
		}
	}
	*/
	
	public void NoDuplicate()
	{
		String test = "";
		String test1 = "1";
		String test2 = "2";
		String test4 = "4";
		if(test == "")
		{
			test1 = "1+1";
		}
	}
}