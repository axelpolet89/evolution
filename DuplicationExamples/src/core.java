/*
 * This class contains a large and small clone (small inner/outer clone, large outer clone)
 */
public class core {
	
	private int initial = 1;
	
	/**
	 * JavaDoc
	 * @param args
	 */
	public static void main(String[] args) {
	}
	
	//comment
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
	
	private int InBetween()
	{
		String test = "this is inbetween";
		return 1;
	}
	
	public void SmalInnerDuplicate()
	{
		String s11 = "s11";
		String test1 = "1";
		String test2 = "2";
		String test3 = "3";
		if(test2 == "")
		{
			test3 = "1+1";
		}
		String s12 = "s12";
	}
}