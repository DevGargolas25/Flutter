const functions = require('firebase-functions');

// Instalar openai: cd functions && npm install openai
const { OpenAI } = require('openai');

// Configurar OpenAI
const openai = new OpenAI({
  apiKey: functions.config().openai.key, // Configuraremos esto después
});

exports.chatWithAI = functions.https.onRequest(async (req, res) => {
  // CORS para Flutter Web y móvil
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.status(200).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  try {
    const { messages } = req.body;
    
    if (!messages || !Array.isArray(messages)) {
      res.status(400).json({ error: 'Messages array is required' });
      return;
    }

    console.log(`📩 Received ${messages.length} messages`);

    // Llamar a OpenAI
    const completion = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: messages,
      max_tokens: 500,
      temperature: 0.7,
    });

    const reply = completion.choices[0].message.content;
    console.log(`✅ OpenAI reply generated`);

    res.json({
      success: true,
      message: reply,
    });

  } catch (error) {
    console.error('❌ Error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});